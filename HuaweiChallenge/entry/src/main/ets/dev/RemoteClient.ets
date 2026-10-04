import { http } from '@kit.NetworkKit';

/** Minimal HTTP helper for the dev-only remote backend. Requires INTERNET (dev). */
export class RemoteClient {
  static async post(url: string, data: string | ArrayBuffer, contentType: string,
    readTimeoutMs: number = 600000): Promise<string> {
    const request: http.HttpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': contentType },
        extraData: data,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: readTimeoutMs
      };
      const response: http.HttpResponse = await request.request(url, options);
      if (response.responseCode !== 200) {
        throw new Error(`remote ${url} -> HTTP ${response.responseCode}`);
      }
      return typeof response.result === 'string' ? response.result : '';
    } finally {
      request.destroy();
    }
  }
}
