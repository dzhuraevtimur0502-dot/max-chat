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