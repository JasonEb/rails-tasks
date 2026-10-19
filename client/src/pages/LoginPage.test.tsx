import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { LoginPage } from './LoginPage'
import { api, ApiError } from '../api'

vi.mock('../api', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../api')>()
  return { ...actual, api: { ...actual.api, login: vi.fn(), signUp: vi.fn() } }
})

const user = { id: 1, email: 'ada@example.com', name: 'Ada', created_at: '' }

describe('LoginPage', () => {
  it('logs in and hands the session to the app', async () => {
    vi.mocked(api.login).mockResolvedValue({ user, token: 'tok' })
    const onAuthenticated = vi.fn()
    render(<LoginPage onAuthenticated={onAuthenticated} />)

    await userEvent.type(screen.getByLabelText('Email'), 'ada@example.com')
    await userEvent.type(screen.getByLabelText('Password'), 'password123')
    await userEvent.click(screen.getByRole('button', { name: 'Log in' }))

    expect(api.login).toHaveBeenCalledWith('ada@example.com', 'password123')
    expect(onAuthenticated).toHaveBeenCalledWith({ user, token: 'tok' })
  })

  it('can switch to sign-up, which asks for a name', async () => {
    vi.mocked(api.signUp).mockResolvedValue({ user, token: 'tok' })
    const onAuthenticated = vi.fn()
    render(<LoginPage onAuthenticated={onAuthenticated} />)

    await userEvent.click(screen.getByRole('button', { name: 'Need an account? Sign up' }))
    await userEvent.type(screen.getByLabelText('Name'), 'Ada')
    await userEvent.type(screen.getByLabelText('Email'), 'ada@example.com')
    await userEvent.type(screen.getByLabelText('Password'), 'password123')
    await userEvent.click(screen.getByRole('button', { name: 'Sign up' }))

    expect(api.signUp).toHaveBeenCalledWith({ name: 'Ada', email: 'ada@example.com', password: 'password123' })
    expect(onAuthenticated).toHaveBeenCalled()
  })

  it('shows the error from the API', async () => {
    vi.mocked(api.login).mockRejectedValue(new ApiError(401, 'Invalid email or password'))
    render(<LoginPage onAuthenticated={vi.fn()} />)

    await userEvent.type(screen.getByLabelText('Email'), 'ada@example.com')
    await userEvent.type(screen.getByLabelText('Password'), 'wrong')
    await userEvent.click(screen.getByRole('button', { name: 'Log in' }))

    expect(await screen.findByRole('alert')).toHaveTextContent('Invalid email or password')
  })
})
