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