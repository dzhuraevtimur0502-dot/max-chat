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