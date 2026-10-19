import { useState } from 'react'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router'
import type { Session } from './api'
import { disconnectCable } from './cable'
import { LoginPage } from './pages/LoginPage'
import { TaskListPage } from './pages/TaskListPage'
import { TaskPage } from './pages/TaskPage'
import { loadSession, saveSession } from './session'

export default function App() {
  const [session, setSession] = useState<Session | null>(loadSession)

  function signIn(next: Session) {
    saveSession(next)
    setSession(next)
  }

  function signOut() {
    disconnectCable()
    saveSession(null)
    setSession(null)
  }

  if (!session) return <LoginPage onAuthenticated={signIn} />

  return (
    <BrowserRouter>
      <nav className="topbar">
        <strong>Rails Tasks</strong>
        <span>
          {session.user.name}{' '}
          <button type="button" className="link" onClick={signOut}>
            Log out
          </button>
        </span>
      </nav>
      <Routes>
        <Route path="/" element={<TaskListPage session={session} />} />
        <Route path="/tasks/:id" element={<TaskPage session={session} />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
