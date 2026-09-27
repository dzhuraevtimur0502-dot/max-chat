export class GreenApi {
  constructor(idInstance, apiTokenInstance) {
    this.idInstance = idInstance;
    this.apiTokenInstance = apiTokenInstance;
    // Используем прямой URL для работы на Vercel
    this.baseUrl = `https://${idInstance.slice(0, 4)}.api.green-api.com/waInstance${idInstance}`;
  }

  async checkAccount(phoneNumber) {
    const res = await fetch(`${this.baseUrl}/checkAccount/${this.apiTokenInstance}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phoneNumber: Number(phoneNumber) }),
    });
    if (!res.ok) throw new Error('CheckAccount error: ' + res.status);
    return res.json();
  }

  async sendMessage(chatId, message) {
    const res = await fetch(`${this.baseUrl}/sendMessage/${this.apiTokenInstance}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chatId, message }),
    });
    if (!res.ok) throw new Error('Send error: ' + res.status);
    return res.json();
  }

  async receiveNotification(timeout = 20) {
    const res = await fetch(
      `${this.baseUrl}/receiveNotification/${this.apiTokenInstance}?timeout=${timeout}`
    );
    if (!res.ok) throw new Error('Receive error: ' + res.status);
    
    const text = await res.text();
    if (text === 'false') return false;
    
    return JSON.parse(text);
  }

  async deleteNotification(receiptId) {
    try {
      const res = await fetch(
        `${this.baseUrl}/deleteNotification/${this.apiTokenInstance}?receiptId=${receiptId}`
      );
      return res;
    } catch (e) {
      console.warn('deleteNotification failed');
      return null;
    }
  }
}
