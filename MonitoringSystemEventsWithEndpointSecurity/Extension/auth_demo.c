/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Functions that initialize the Endpoint Security system extension to receive AUTH events.
*/

#include <EndpointSecurity/EndpointSecurity.h>
#include <dispatch/queue.h>
#include <bsm/libbsm.h>
#include <stdio.h>
#include <os/log.h>

static dispatch_queue_t g_event_queue = NULL;

static void
init_dispatch_queue(void)
{
	// Choose an appropriate Quality of Service class appropriate for your app.
	// https://developer.apple.com/documentation/dispatch/dispatchqos
	dispatch_queue_attr_t queue_attrs = dispatch_queue_attr_make_with_qos_class(
			DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INITIATED, 0);

	g_event_queue = dispatch_queue_create("event_queue", queue_attrs);
}

static bool
is_eicar_file(const es_file_t *file)
{
    // The EICAR test file string, as defined by the EICAR standard.
	static const char* eicar = "X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*";
	static const off_t eicar_length = sizeof(eicar) - 1;
	static const off_t eicar_max_length = 128;

	bool result = false;

	// EICAR check
	// First: ensure the length matches defined EICAR requirements.
	if (file->stat.st_size >= eicar_length && file->stat.st_size <= eicar_max_length) {
		//Second: Open the file and read the data.
		int fd = open(file->path.data, O_RDONLY);
		if (fd >= 0) {
			uint8_t buf[sizeof(eicar)];
			ssize_t bytes_read = read(fd, buf, sizeof(buf));
			if (bytes_read >= eicar_length) {
				//Third: Test the file contents against the EICAR test string.
				if (memcmp(buf, eicar, sizeof(buf)) == 0) {
					result = true;
				}
			}

			close(fd);
		}
	}

	return result;
}

static void
handle_exec(es_client_t *client, const es_message_t *msg)
{
    // To keep the code simple, this example denies execution based on signing ID.
    // However this isn't a very restrictive policy and could inadvertently lead to
    // denying more executions than intended. In general, you should consider using
    // more restrictive policies like inspecting the process's CDHash instead.
	static const char *signing_id_to_block = "com.apple.TextEdit";

	if (strcmp(msg->event.exec.target->signing_id.data, signing_id_to_block) == 0) {
		es_respond_auth_result(client, msg, ES_AUTH_RESULT_DENY, true);
	} else {
		es_respond_auth_result(client, msg, ES_AUTH_RESULT_ALLOW, true);
	}
}

static void
handle_open_worker(es_client_t *client, es_message_t *msg)
{
	static const char *ro_prefix = "/usr/local/bin/";
	static const size_t ro_prefix_length = sizeof(ro_prefix) - 1;

	if (is_eicar_file(msg->event.open.file)) {
		// Don't allow any operations on EICAR files.
		es_respond_flags_result(client, msg, 0, true);
	} else if (strncmp(msg->event.open.file->path.data, ro_prefix, ro_prefix_length) == 0) {
		// Deny writing to paths that match the readonly prefix.
		es_respond_flags_result(client, msg, 0xffffffff & ~FWRITE, true);
	} else {
		// Allow everything else...
		es_respond_flags_result(client, msg, 0xffffffff, true);
	}
}

static void
handle_open(es_client_t *client, const es_message_t *msg)
{
	es_message_t *copied_msg = es_copy_message(msg);

	dispatch_async(g_event_queue, ^{
		handle_open_worker(client, copied_msg);
		es_free_message(copied_msg);
	});
}

static void
handle_event(es_client_t *client, const es_message_t *msg)
{

	switch (msg->event_type) {
		case ES_EVENT_TYPE_AUTH_EXEC:
			handle_exec(client, msg);
			break;

		case ES_EVENT_TYPE_AUTH_OPEN:
			handle_open(client, msg);
			break;

		default:
			if (msg->action_type == ES_ACTION_TYPE_AUTH) {
				es_respond_auth_result(client, msg, ES_AUTH_RESULT_ALLOW, true);
			}
			break;
	}
}

int
main(int argc, char *argv[])
{
	init_dispatch_queue();

	es_client_t *client;
	es_new_client_result_t result = es_new_client(&client, ^(es_client_t *c, const es_message_t *msg) {
		handle_event(c, msg);
	});

	if (result != ES_NEW_CLIENT_RESULT_SUCCESS) {
		os_log_error(OS_LOG_DEFAULT, "Failed to create the ES client: %d", result);
		return 1;
	}

	es_event_type_t events[] = { ES_EVENT_TYPE_AUTH_EXEC, ES_EVENT_TYPE_AUTH_OPEN };
	if (es_subscribe(client, events, sizeof(events) / sizeof(events[0])) != ES_RETURN_SUCCESS) {
		os_log_error(OS_LOG_DEFAULT, "Failed to subscribe to events");
		es_delete_client(client);
		return 1;
	}

	dispatch_main();

	return 0;
}
