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
            <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="79876664128" autoFocus />
            <button type="submit">OK</button>
          </form>
        )}
      </div>

      <ul className="chat-list">
        {chats.map((chat) => (
          <li
            key={chat.chatId}
            className={`chat-item ${activeChat === chat.chatId ? 'active' : ''}`}
            onClick={() => onSelect(chat.chatId)}
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
