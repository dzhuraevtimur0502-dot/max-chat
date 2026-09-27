# ===== Хелпер для записи файлов в UTF-8 без BOM =====
function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText((Join-Path $PWD $path), $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Created: $path" -ForegroundColor Green
}

# ===== src/services/greenApi.js =====
Write-File "src\services\greenApi.js" @'
const BASE_URL = 'https://api.green-api.com';

export class GreenApi {
  constructor(idInstance, apiTokenInstance) {
    this.idInstance = idInstance;
    this.apiTokenInstance = apiTokenInstance;
    this.baseUrl = `${BASE_URL}/waInstance${idInstance}`;
  }

  async sendMessage(chatId, message) {
    const res = await fetch(`${this.baseUrl}/sendMessage/${this.apiTokenInstance}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chatId, message }),
    });
    if (!res.ok) throw new Error('Send error');
    return res.json();
  }

  async receiveNotification(timeout = 20) {
    const res = await fetch(
      `${this.baseUrl}/receiveNotification/${this.apiTokenInstance}?timeout=${timeout}`
    );
    return res.json();
  }

  async deleteNotification(receiptId) {
    await fetch(
      `${this.baseUrl}/deleteNotification/${this.apiTokenInstance}?receiptId=${receiptId}`
    );
  }
}
'@

# ===== src/App.jsx =====
Write-File "src\App.jsx" @'
import { useState } from 'react';
import AuthForm from './components/AuthForm';
import Messenger from './components/Messenger';

export default function App() {
  const [credentials, setCredentials] = useState(null);

  return credentials ? (
    <Messenger credentials={credentials} onLogout={() => setCredentials(null)} />
  ) : (
    <AuthForm onSubmit={setCredentials} />
  );
}
'@

# ===== src/components/AuthForm.jsx =====
Write-File "src\components\AuthForm.jsx" @'
import { useState } from 'react';

export default function AuthForm({ onSubmit }) {
  const [idInstance, setIdInstance] = useState('');
  const [token, setToken] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!idInstance.trim() || !token.trim()) return;
    onSubmit({ idInstance: idInstance.trim(), apiTokenInstance: token.trim() });
  };

  return (
    <div className="auth-screen">
      <form className="auth-card" onSubmit={handleSubmit}>
        <h1>MAX Chat</h1>
        <p className="auth-subtitle">Login via GREEN-API</p>
        <label>
          idInstance
          <input value={idInstance} onChange={(e) => setIdInstance(e.target.value)} placeholder="1103xxxxxx" />
        </label>
        <label>
          apiTokenInstance
          <input type="password" value={token} onChange={(e) => setToken(e.target.value)} placeholder="xxxxxxxxxx" />
        </label>
        <button type="submit">Login</button>
      </form>
    </div>
  );
}
'@

# ===== src/components/Messenger.jsx =====
Write-File "src\components\Messenger.jsx" @'
import { useEffect, useRef, useState } from 'react';
import { GreenApi } from '../services/greenApi';
import Sidebar from './Sidebar';
import ChatWindow from './ChatWindow';

export default function Messenger({ credentials, onLogout }) {
  const apiRef = useRef(new GreenApi(credentials.idInstance, credentials.apiTokenInstance));
  const [chats, setChats] = useState({});
  const [activeChat, setActiveChat] = useState(null);

  const addMessage = (chatId, message) => {
    setChats((prev) => {
      const chat = prev[chatId] || { phone: chatId, messages: [] };
      return { ...prev, [chatId]: { ...chat, messages: [...chat.messages, message] } };
    });
  };

  useEffect(() => {
    let stopped = false;
    const api = apiRef.current;

    const poll = async () => {
      while (!stopped) {
        try {
          const notification = await api.receiveNotification();
          if (notification?.body?.typeWebhook === 'incomingMessageReceived') {
            const { senderData, messageData } = notification.body;
            const chatId = senderData.chatId || senderData.sender;
            addMessage(chatId, {
              id: messageData?.idMessage || Date.now(),
              text: messageData?.textMessage || '',
              incoming: true,
              timestamp: messageData?.timestamp || Math.floor(Date.now() / 1000),
            });
            setActiveChat((prev) => prev || chatId);
          }
          if (notification?.receiptId) {
            await api.deleteNotification(notification.receiptId);
          }
        } catch {
          await new Promise((r) => setTimeout(r, 3000));
        }
      }
    };
    poll();
    return () => { stopped = true; };
  }, []);

  const createChat = (phone) => {
    const chatId = phone.replace(/\D/g, '');
    setChats((prev) => (prev[chatId] ? prev : { ...prev, [chatId]: { phone: chatId, messages: [] } }));
    setActiveChat(chatId);
  };

  const sendMessage = async (text) => {
    if (!activeChat || !text.trim()) return;
    const tempId = `temp-${Date.now()}`;
    addMessage(activeChat, { id: tempId, text, incoming: false, timestamp: Math.floor(Date.now() / 1000), status: 'sent' });
    try {
      const res = await apiRef.current.sendMessage(activeChat, text);
      setChats((prev) => ({
        ...prev,
        [activeChat]: {
          ...prev[activeChat],
          messages: prev[activeChat].messages.map((m) =>
            m.id === tempId ? { ...m, id: res.idMessage, status: 'delivered' } : m
          ),
        },
      }));
    } catch {
      /* show error status here if needed */
    }
  };

  return (
    <div className="messenger">
      <Sidebar
        chats={Object.values(chats)}
        activeChat={activeChat}
        onSelect={setActiveChat}
        onCreateChat={createChat}
        onLogout={onLogout}
      />
      {activeChat ? (
        <ChatWindow chat={chats[activeChat]} onSend={sendMessage} />
      ) : (
        <div className="empty-state">Select a chat or create a new one</div>
      )}
    </div>
  );
}
'@

# ===== src/components/Sidebar.jsx =====
Write-File "src\components\Sidebar.jsx" @'
import { useState } from 'react';

export default function Sidebar({ chats, activeChat, onSelect, onCreateChat, onLogout }) {
  const [phone, setPhone] = useState('');
  const [showForm, setShowForm] = useState(false);

  const submit = (e) => {
    e.preventDefault();
    if (!phone.trim()) return;
    onCreateChat(phone);
    setPhone('');
    setShowForm(false);
  };

  return (
    <aside className="sidebar">
      <header className="sidebar-header">
        <span className="logo">MAX Chat</span>
        <button className="icon-btn" onClick={onLogout} title="Logout">X</button>
      </header>

      <div className="new-chat">
        {!showForm ? (
          <button className="new-chat-btn" onClick={() => setShowForm(true)}>+ New chat</button>
        ) : (
          <form onSubmit={submit} className="new-chat-form">
            <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="79991234567" autoFocus />
            <button type="submit">OK</button>
          </form>
        )}
      </div>

      <ul className="chat-list">
        {chats.map((chat) => (
          <li
            key={chat.phone}
            className={`chat-item ${activeChat === chat.phone ? 'active' : ''}`}
            onClick={() => onSelect(chat.phone)}
          >
            <div className="avatar">+{chat.phone.slice(0, 2)}</div>
            <div className="chat-preview">
              <span className="chat-phone">+{chat.phone}</span>
              <span className="chat-last">{chat.messages.length ? chat.messages[chat.messages.length - 1].text : 'No messages'}</span>
            </div>
          </li>
        ))}
      </ul>
    </aside>
  );
}
'@

# ===== src/components/ChatWindow.jsx =====
Write-File "src\components\ChatWindow.jsx" @'
import { useEffect, useRef, useState } from 'react';

export default function ChatWindow({ chat, onSend }) {
  const [text, setText] = useState('');
  const bottomRef = useRef(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chat.messages.length]);

  const submit = (e) => {
    e.preventDefault();
    if (!text.trim()) return;
    onSend(text.trim());
    setText('');
  };

  const fmt = (ts) => new Date(ts * 1000).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });

  return (
    <main className="chat-window">
      <header className="chat-header">
        <div className="avatar">+{chat.phone.slice(0, 2)}</div>
        <div>
          <div className="chat-title">+{chat.phone}</div>
          <div className="chat-status">MAX</div>
        </div>
      </header>

      <div className="messages">
        {chat.messages.map((m) => (
          <div key={m.id} className={`bubble ${m.incoming ? 'incoming' : 'outgoing'}`}>
            <span className="bubble-text">{m.text}</span>
            <span className="bubble-time">
              {fmt(m.timestamp)}
              {!m.incoming && <span className="ticks">{m.status === 'delivered' ? 'VV' : 'V'}</span>}
            </span>
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      <form className="message-input" onSubmit={submit}>
        <input value={text} onChange={(e) => setText(e.target.value)} placeholder="Type a message..." />
        <button type="submit" disabled={!text.trim()}>Send</button>
      </form>
    </main>
  );
}
'@

# ===== src/index.css =====
Write-File "src\index.css" @'
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Segoe UI', Roboto, sans-serif; background: #e8ecf1; }

.messenger { display: flex; height: 100vh; }

.sidebar { width: 320px; background: #fff; border-right: 1px solid #dce1e6; display: flex; flex-direction: column; }
.sidebar-header { padding: 16px; display: flex; justify-content: space-between; align-items: center; }
.logo { font-weight: 700; color: #0077ff; font-size: 18px; }
.icon-btn { border: none; background: none; cursor: pointer; color: #8a94a0; font-size: 16px; }
.new-chat { padding: 0 12px 12px; }
.new-chat-btn { width: 100%; padding: 10px; border: none; border-radius: 10px; background: #0077ff; color: #fff; cursor: pointer; }
.new-chat-form { display: flex; gap: 6px; }
.new-chat-form input { flex: 1; padding: 9px; border: 1px solid #cfd6dd; border-radius: 10px; }
.chat-list { list-style: none; overflow-y: auto; flex: 1; }
.chat-item { display: flex; gap: 10px; padding: 12px; cursor: pointer; }
.chat-item:hover { background: #f2f5f8; }
.chat-item.active { background: #0077ff; color: #fff; }
.avatar { width: 44px; height: 44px; border-radius: 50%; background: #0077ff; color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 600; flex-shrink: 0; }
.chat-preview { display: flex; flex-direction: column; overflow: hidden; }
.chat-last { color: #8a94a0; font-size: 13px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.chat-item.active .chat-last { color: #dceaff; }

.chat-window { flex: 1; display: flex; flex-direction: column; background: #dfe6ee; }
.chat-header { padding: 12px 16px; background: #fff; display: flex; gap: 12px; align-items: center; border-bottom: 1px solid #dce1e6; }
.messages { flex: 1; overflow-y: auto; padding: 20px; display: flex; flex-direction: column; gap: 8px; }
.bubble { max-width: 65%; padding: 10px 14px; border-radius: 16px; font-size: 15px; line-height: 1.4; }
.bubble.incoming { align-self: flex-start; background: #fff; border-bottom-left-radius: 4px; }
.bubble.outgoing { align-self: flex-end; background: #cce4ff; border-bottom-right-radius: 4px; }
.bubble-time { display: block; text-align: right; font-size: 11px; color: #8a94a0; margin-top: 4px; }
.ticks { color: #0077ff; margin-left: 4px; }
.message-input { display: flex; gap: 8px; padding: 12px 16px; background: #fff; }
.message-input input { flex: 1; padding: 12px; border: 1px solid #cfd6dd; border-radius: 12px; font-size: 15px; }
.message-input button { padding: 0 18px; border: none; border-radius: 12px; background: #0077ff; color: #fff; font-size: 14px; cursor: pointer; }
.message-input button:disabled { opacity: 0.5; }
.empty-state { flex: 1; display: flex; align-items: center; justify-content: center; color: #8a94a0; }

.auth-screen { height: 100vh; display: flex; align-items: center; justify-content: center; }
.auth-card { background: #fff; padding: 36px; border-radius: 16px; box-shadow: 0 8px 30px rgba(0,0,0,0.1); width: 360px; display: flex; flex-direction: column; gap: 14px; }
.auth-card h1 { color: #0077ff; }
.auth-subtitle { color: #8a94a0; font-size: 14px; }
.auth-card label { display: flex; flex-direction: column; gap: 6px; font-size: 13px; color: #555; }
.auth-card input { padding: 11px; border: 1px solid #cfd6dd; border-radius: 10px; }
.auth-card button { padding: 12px; border: none; border-radius: 10px; background: #0077ff; color: #fff; font-size: 15px; cursor: pointer; }
'@

# ===== README.md =====
Write-File "README.md" @'
# MAX Chat - Test task (Frontend React + GREEN-API)

Web chat for sending and receiving text messages in MAX messenger via GREEN-API.

## Tech stack
React (Vite), JavaScript, CSS, GREEN-API REST (SendMessage, ReceiveNotification)

## Local run
1. git clone https://github.com/YOUR_LOGIN/max-chat.git
2. cd max-chat && npm install
3. npm run dev
4. Open http://localhost:5173
5. Enter idInstance and apiTokenInstance from GREEN-API console (https://console.green-api.com)
6. Create a chat by phone number and send a message

## Deploy
https://max-chat.vercel.app
'@

# ===== Правим заголовок в index.html =====
$html = Get-Content index.html -Raw
$html = $html -replace '<title>.*</title>', '<title>MAX Chat</title>'
[System.IO.File]::WriteAllText((Join-Path $PWD 'index.html'), $html, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Updated: index.html" -ForegroundColor Green

Write-Host "`nAll files created! Run: npm run dev" -ForegroundColor Yellow