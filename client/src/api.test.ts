import { afterEach, describe, expect, it, vi } from 'vitest'
import { ApiError, api } from './api'

function mockFetch(status: number, body: unknown) {
  const fetchMock = vi.fn().mockResolvedValue(
    new Response(status === 204 ? null : JSON.stringify(body), {
      status,
      headers: { 'Content-Type': 'application/json' },
    }),
  )
  vi.stubGlobal('fetch', fetchMock)
  return fetchMock
}

afterEach(() => {
  vi.unstubAllGlobals()
})

describe('api', () => {
  it('sends the bearer token and JSON body', async () => {
    const fetchMock = mockFetch(201, { task: { id: 1 } })

    await api.createTask('secret', { title: 'Write tests' })

    const [url, init] = fetchMock.mock.calls[0]
    expect(url).toBe('http://localhost:3000/api/v1/tasks')
    expect(init.method).toBe('POST')
    expect(init.headers.Authorization).toBe('Bearer secret')
    expect(JSON.parse(init.body)).toEqual({ task: { title: 'Write tests' } })
  })

  it('throws an ApiError carrying field errors on 422', async () => {
    mockFetch(422, { errors: { title: ["can't be blank"] } })

    const error = await api.createTask('secret', { title: '' }).catch((e) => e)

    expect(error).toBeInstanceOf(ApiError)
    expect(error.status).toBe(422)
    expect(error.message).toBe("title can't be blank")
  })

  it('returns null for 204 No Content', async () => {
    mockFetch(204, null)

    await expect(api.deleteComment('secret', 5)).resolves.toBeNull()
  })

  it('passes the cursor when loading comments', async () => {
    const fetchMock = mockFetch(200, { comments: [], next_cursor: null, limit: 50 })

    await api.comments('secret', 7, 42)

    expect(fetchMock.mock.calls[0][0]).toBe('http://localhost:3000/api/v1/tasks/7/comments?after=42')
  })
})
