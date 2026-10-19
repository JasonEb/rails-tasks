import { useState, type FormEvent } from 'react'
import { api, type Session } from '../api'

export function LoginPage({ onAuthenticated }: { onAuthenticated: (session: Session) => void }) {
  const [mode, setMode] = useState<'login' | 'signup'>('login')
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError(null)
    try {
      const session = mode === 'login' ? await api.login(email, password) : await api.signUp({ name, email, password })
      onAuthenticated(session)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Something went wrong')
    } finally {
      setBusy(false)
    }
  }

  const isLogin = mode === 'login'

  return (
    <main className="card narrow">
      <h1>{isLogin ? 'Log in' : 'Sign up'}</h1>
      <form onSubmit={handleSubmit} className="stack">
        {!isLogin && (
          <label>
            Name
            <input value={name} onChange={(e) => setName(e.target.value)} required />
          </label>
        )}
        <label>
          Email
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </label>
        <label>
          Password
          <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        </label>
        {error && <p role="alert" className="error">{error}</p>}
        <button type="submit" disabled={busy}>{isLogin ? 'Log in' : 'Sign up'}</button>
      </form>
      <button type="button" className="link" onClick={() => setMode(isLogin ? 'signup' : 'login')}>
        {isLogin ? 'Need an account? Sign up' : 'Have an account? Log in'}
      </button>
    </main>
  )
}
