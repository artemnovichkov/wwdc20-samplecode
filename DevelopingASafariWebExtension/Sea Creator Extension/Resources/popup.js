/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Script that runs after clicking the extension's toolbar button.
*/
function shareOnExample()
{
    // Use optional permissions to request access to www.example.com.
    browser.permissions.request({origins: ['https://www.example.com/']}, (granted) => {
        if (granted) {
            // Share Sea Creator's info to example.com.
        }
    });
}

document.addEventListener("DOMContentLoaded", () => {
    document.getElementById("share").addEventListener("click", shareOnExample);
});
