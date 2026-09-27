import { useEffect, useRef, useState } from 'react';
import { GreenApi } from '../services/greenApi';
import Sidebar from './Sidebar';
import ChatWindow from './ChatWindow';

export default function Messenger({ credentials, onLogout }) {
  const apiRef = useRef(new GreenApi(credentials.idInstance, credentials.apiTokenInstance));
  const [chats, setChats] = useState({});
  const [activeChat, setActiveChat] = useState(null);
  const processedReceipts = useRef(new Set());

  const addMessage = (chatId, message) => {
    setChats((prev) => {
      const chat = prev[chatId] || { chatId, phone: chatId, name: chatId, messages: [] };
      return { ...prev, [chatId]: { ...chat, messages: [...chat.messages, message] } };
    });
  };

  useEffect(() => {
    let stopped = false;
    const api = apiRef.current;

    const poll = async () => {
      while (!stopped) {
        try {
          const notification = await api.receiveNotification(20);
          
          if (notification === false) {
            console.log('Нет новых сообщений, ждём 60 сек...');
            await new Promise((r) => setTimeout(r, 60000));
            continue;
          }

          const receiptId = notification?.receiptId;
          
          if (receiptId && processedReceipts.current.has(receiptId)) {
            console.log('⏭️ Дубликат, пропускаем');
            await new Promise((r) => setTimeout(r, 60000));
            continue;
          }
          
          if (receiptId) {
            processedReceipts.current.add(receiptId);
          }

          console.log(' Notification:', notification);
          console.log('️ Type:', notification?.body?.typeWebhook);

          if (notification?.body?.typeWebhook === 'incomingMessageReceived') {
            const { senderData, messageData } = notification.body;
            const chatId = String(senderData.chatId || senderData.sender);
            console.log('📨 Incoming from:', chatId, messageData?.textMessage);
            
            addMessage(chatId, {
              id: messageData?.idMessage || Date.now(),
              text: messageData?.textMessage || '',
              incoming: true,
              timestamp: messageData?.timestamp || Math.floor(Date.now() / 1000),
            });
            
            setActiveChat((prev) => prev || chatId);
          }

          if (receiptId) {
            await api.deleteNotification(receiptId);
          }
          
          await new Promise((r) => setTimeout(r, 60000));
        } catch (e) {
          console.error('❌ Polling error:', e.message);
          if (e.message.includes('429')) {
            console.log('⚠️ Rate limit, ждём 120 секунд...');
            await new Promise((r) => setTimeout(r, 120000));
          } else {
            await new Promise((r) => setTimeout(r, 60000));
          }
        }
      }
    };
    
    poll();
    return () => { stopped = true; };
  }, []);

  const createChat = async (phone) => {
    const digits = phone.replace(/\D/g, '');
    try {
      const res = await apiRef.current.checkAccount(digits);
      if (!res?.exist || !res?.chatId) {
        alert('На этом номере нет аккаунта MAX');
        return;
      }
      const chatId = String(res.chatId);
      setChats((prev) => (prev[chatId] ? prev : { ...prev, [chatId]: { chatId, phone: digits, name: chatId, messages: [] } }));
      setActiveChat(chatId);
    } catch (e) {
      alert('Ошибка проверки номера: ' + e.message);
    }
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
    } catch (e) {
      console.error('Send error:', e);
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
