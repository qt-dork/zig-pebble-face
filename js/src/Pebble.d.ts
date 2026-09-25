type WatchInfo = {
    platform: 'aplite' | 'basalt' | 'chalk' | 'diorite' | 'emery' | 'unknown';
    model: string
    language: string;
    firmware: {
        major: number;
        minor: number;
        patch: number;
        suffix: string;
    }
}

type AppGlanceSlice = {
    expirationTime?: number;
    layout: {
        icon: string;
        subtitleTemplateString: string;
    }
}

type AppGlanceReloadSuccessCallback = {
    AppGlanceSlices: AppGlanceSlice[];
}

type AppGlanceReloadFailureCallback = {
    AppGlanceSlices: AppGlanceSlice[];
}

type EventCallback = {
    type: 'ready' | 'appmessage' | 'showConfiguration' | 'webviewclosed' | 'message' | 'postmessageconnected' | 'postmessagedisconnected' | 'postmessageerror';
    payload: any;
    response: any;
};

type AppMessageAckCallback = {
    data: any;
};

type AppMessageNackCallback = {
    data: any;
    error: string;
};

type TimelineTokenCallback = {
    token: string;
};

declare var Pebble: {
    /**
     * Adds a listener for PebbleKit JS events, such as when an AppMessage is received or the configuration view is opened or closed.
     * @param type The type of the event, from the list described above.
     * @param callback The developer defined EventCallback to receive any events of the type specified that occur.
     * @returns void
     * @link https://developer.rebble.io/developer.pebble.com/docs/pebblekit-js/Pebble/index.html#addEventListener
     */
    addEventListener: (type: 'ready' | 'appmessage' | 'showConfiguration' | 'webviewclosed' | 'message' | 'postmessageconnected' | 'postmessagedisconnected' | 'postmessageerror', callback: (e: EventCallback) => void) => void;
    on: (type: 'ready' | 'appmessage' | 'showConfiguration' | 'webviewclosed' | 'message' | 'postmessageconnected' | 'postmessagedisconnected' | 'postmessageerror', callback: (e: EventCallback) => void) => void;

    /**
     * Remove an existing event listener previously registered with Pebble.addEventListener() or Pebble.on().
     * @param type The type of the event listener to be removed. See Pebble.addEventListener() for a list of available event types.
     * @param callback The existing developer-defined function that was previously registered.
     * @returns void
     * @link https://developer.rebble.io/developer.pebble.com/docs/pebblekit-js/Pebble/index.html#removeEventListener
     */
    removeEventListener: (type: 'ready' | 'appmessage' | 'showConfiguration' | 'webviewclosed' | 'message' | 'postmessageconnected' | 'postmessagedisconnected' | 'postmessageerror', callback: (...args: any[]) => void) => void;
    off: (type: 'ready' | 'appmessage' | 'showConfiguration' | 'webviewclosed' | 'message' | 'postmessageconnected' | 'postmessagedisconnected' | 'postmessageerror', callback: (...args: any[]) => void) => void;

    /**
     * Show a simple modal notification on the connected watch.
     * @param title The title of the notification
     * @param body The main content of the notification
     * @returns void
     * @link https://developer.rebble.io/developer.pebble.com/docs/pebblekit-js/Pebble/index.html#showSimpleNotificationOnPebble
     */
    showSimpleNotificationOnPebble: (title: string, body: string) => void;

    /**
     * Send an AppMessage to the app running on the watch. Messages should be in the form of JSON objects containing key-value pairs. See Pebble.sendAppMessage() for valid key and value data types. Pebble.sendAppMessage = function(data, onSuccess, onFailure) { }; Please note that sendAppMessage is undefined in Rocky.js applications, see postMessage instead.
     * @param message A JSON object containing key-value pairs to send to the watch. Values in arrays that are greater then 255 will be mod 255 before sending.
     * @param ack A developer-defined {AppMessageAckCallback} callback to run if the watch acknowledges (ACK) this message.
     * @param nack A developer-defined {AppMessageNackCallback} callback to run if the watch does NOT acknowledge (NACK) this message.
     * @returns void
     * @link https://developer.rebble.io/developer.pebble.com/docs/pebblekit-js/Pebble/index.html#sendAppMessage
     */
    sendAppMessage: (message: object, ack: (e: AppMessageAckCallback) => void, nack: (e: AppMessageNackCallback) => void) => void;

    /**
     * Sends a message to the Rocky.js component. Please be aware that messages should be kept concise. Each message is queued, so postMessage() can be called multiple times immediately. If there is a momentary loss of connectivity, queued messages may still be delivered, or automatically removed from the queue after a few seconds of failed connectivity. Any transmission failures, or out of memory errors will be raised via the postmessageerror event.
     * @param data An object containing the data to deliver to the watch. This will be received in the data field of the type delivered to the on('message', ...) handler.
     * @returns void
     * @link https://developer.rebble.io/developer.pebble.com/docs/pebblekit-js/Pebble/index.html#postMessage
     */
    postMessage: (data: any) => void;

    /**
     * Get the user's timeline token for this app. This is a string and is unique per user per app. Note: In order for timeline tokens to be available, the app must be submitted to the Pebble appstore, but does not need to be public. Read more in the timeline guides.
     * @param onSuccess A developer-defined TimelineTokenCallback callback to handle a successful attempt to get the timeline token.
     * @param onFailure A developer-defined callback to handle a failed attempt to get the timeline token.
     * @returns void
     * @link https://developer.rebble.io/developer.pebble.com/docs/pebblekit-js/Pebble/index.html#getTimelineToken
     */
    getTimelineToken: (onSuccess: (e: TimelineTokenCallback) => void, onFailure: () => void) => void;

    /**
     * Obtain an object containing information on the currently connected Pebble smartwatch.
     * @returns WatchInfo
     * @link https://developer.rebble.io/developer.pebble.com/docs/pebblekit-js/Pebble/index.html#getActiveWatchInfo
     */
    getActiveWatchInfo: () => WatchInfo;

    /**
     * Returns a unique account token that is associated with the Pebble account of the current user.
     * @returns A string that is guaranteed to be identical across devices if the user owns several Pebble or several mobile devices. From the developer's perspective, the account token of a user is identical across platforms and across all the developer's watchapps. If the user is not logged in, this function will return an empty string ('').
     * @link https://developer.rebble.io/developer.pebble.com/docs/pebblekit-js/Pebble/index.html#getAccountToken
     */
    getAccountToken: () => string;

    /**
     * Returns a a unique token that can be used to identify a Pebble device.
     * @returns A string that is is guaranteed to be identical for each Pebble device for the same app across different mobile devices. The token is unique to your app and cannot be used to track Pebble devices across applications.
     */
    getWatchToken: () => string;

    /**
     * When an app is marked as configurable, the PebbleKit JS component must implement Pebble.openURL() in the showConfiguration event handler. The Pebble mobile app will launch the supplied URL to allow the user to configure the watchapp or watchface. See the App Configuration guide.
     * @param url The URL of the static configuration page.
     * @returns void
     * @link https://developer.rebble.io/developer.pebble.com/docs/pebblekit-js/Pebble/index.html#openURL
     */
    openURL: (url: string) => void;
};
