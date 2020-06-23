/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Functions that initialize the Endpoint Security system extension to receive NOTIFY events.
*/

#include <EndpointSecurity/EndpointSecurity.h>
#include <dispatch/queue.h>
#include <bsm/libbsm.h>
#include <stdio.h>
#include <os/log.h>

static void
handle_event(es_client_t *client, const es_message_t *msg)
{
	switch (msg->event_type) {
		case ES_EVENT_TYPE_NOTIFY_EXEC:
			os_log(OS_LOG_DEFAULT, "%{public}s (pid: %d) | EXEC: New image: %{public}s",
				msg->process->executable->path.data,
				audit_token_to_pid(msg->process->audit_token),
				msg->event.exec.target->executable->path.data);
			break;

		case ES_EVENT_TYPE_NOTIFY_FORK:
			os_log(OS_LOG_DEFAULT, "%{public}s (pid: %d) | FORK: Child pid: %d",
				msg->process->executable->path.data,
				audit_token_to_pid(msg->process->audit_token),
				audit_token_to_pid(msg->event.fork.child->audit_token));
			break;

		case ES_EVENT_TYPE_NOTIFY_EXIT:
			os_log(OS_LOG_DEFAULT, "%{public}s (pid: %d) | EXIT: status: %d",
				msg->process->executable->path.data,
				audit_token_to_pid(msg->process->audit_token),
				msg->event.exit.stat);
			break;

		default:
			os_log_error(OS_LOG_DEFAULT, "Unexpected event type encountered: %d\n", msg->event_type);
			break;
	}
}

int
main(int argc, char *argv[])
{
	es_client_t *client;
	es_new_client_result_t result = es_new_client(&client, ^(es_client_t *c, const es_message_t *msg) {
		handle_event(c, msg);
	});

	if (result != ES_NEW_CLIENT_RESULT_SUCCESS) {
		os_log_error(OS_LOG_DEFAULT, "Failed to create new ES client: %d", result);
		return 1;
	}

	es_event_type_t events[] = { ES_EVENT_TYPE_NOTIFY_EXEC, ES_EVENT_TYPE_NOTIFY_FORK, ES_EVENT_TYPE_NOTIFY_EXIT };

	if (es_subscribe(client, events, sizeof(events) / sizeof(events[0])) != ES_RETURN_SUCCESS) {
		os_log_error(OS_LOG_DEFAULT, "Failed to subscribe to events");
		es_delete_client(client);
		return 1;
	}

	dispatch_main();

	return 0;
}
