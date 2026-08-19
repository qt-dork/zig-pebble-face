declare const Pebble: {
  addEventListener: (type: string, callback: (event: { type: string; payload: any; response: any }) => void) => void;
  sendAppMessage: (message: Record<string, any>, onSuccess: (data: object) => void, onFailure: (error: string) => void) => void;
  openURL: (url: string) => void;
};
