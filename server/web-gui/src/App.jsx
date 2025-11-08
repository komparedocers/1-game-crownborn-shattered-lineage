import { useState, useEffect } from 'react'
import axios from 'axios'
import './App.css'

const API_BASE = import.meta.env.DEV ? 'http://localhost:8000' : ''

function App() {
  const [leaderboard, setLeaderboard] = useState([])
  const [mode, setMode] = useState('fastest_total')
  const [country, setCountry] = useState('')
  const [loading, setLoading] = useState(false)

  const countries = [
    { code: '', name: 'Global' },
    { code: 'US', name: 'United States' },
    { code: 'GB', name: 'United Kingdom' },
    { code: 'CA', name: 'Canada' },
    { code: 'AU', name: 'Australia' },
    { code: 'DE', name: 'Germany' },
    { code: 'FR', name: 'France' },
    { code: 'JP', name: 'Japan' },
    { code: 'KR', name: 'South Korea' },
    { code: 'BR', name: 'Brazil' },
    { code: 'IN', name: 'India' },
  ]

  useEffect(() => {
    fetchLeaderboard()
  }, [mode, country])

  const fetchLeaderboard = async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams({ mode })
      if (country) params.append('country', country)

      const response = await axios.get(`${API_BASE}/v1/leaderboard/global?${params}`)
      setLeaderboard(response.data.entries)
    } catch (error) {
      console.error('Failed to fetch leaderboard:', error)
      setLeaderboard([])
    } finally {
      setLoading(false)
    }
  }

  const formatTime = (ms) => {
    if (!ms) return '-'
    const seconds = Math.floor(ms / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)

    if (hours > 0) {
      return `${hours}h ${minutes % 60}m ${seconds % 60}s`
    } else if (minutes > 0) {
      return `${minutes}m ${seconds % 60}s`
    } else {
      return `${seconds}s`
    }
  }

  const getRankColor = (rank) => {
    if (rank === 1) return 'text-yellow-400'
    if (rank === 2) return 'text-gray-300'
    if (rank === 3) return 'text-orange-400'
    return 'text-white'
  }

  const getRankMedal = (rank) => {
    if (rank === 1) return '🥇'
    if (rank === 2) return '🥈'
    if (rank === 3) return '🥉'
    return rank
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-crown-dark via-crown-accent to-black">
      <div className="container mx-auto px-4 py-8">
        <header className="text-center mb-12">
          <h1 className="text-5xl font-bold text-crown-gold mb-2">
            Crownborn: Shattered Lineage
          </h1>
          <p className="text-xl text-gray-300">Global Leaderboard</p>
        </header>

        <div className="max-w-4xl mx-auto bg-crown-accent rounded-lg shadow-2xl p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Leaderboard Mode
              </label>
              <select
                value={mode}
                onChange={(e) => setMode(e.target.value)}
                className="w-full bg-crown-dark text-white rounded px-4 py-2 border border-crown-gold focus:outline-none focus:ring-2 focus:ring-crown-gold"
              >
                <option value="fastest_total">Fastest Total Time</option>
                <option value="highest_stage">Highest Stage Reached</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Country Filter
              </label>
              <select
                value={country}
                onChange={(e) => setCountry(e.target.value)}
                className="w-full bg-crown-dark text-white rounded px-4 py-2 border border-crown-gold focus:outline-none focus:ring-2 focus:ring-crown-gold"
              >
                {countries.map((c) => (
                  <option key={c.code} value={c.code}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {loading ? (
            <div className="text-center py-12">
              <div className="inline-block animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-crown-gold"></div>
              <p className="mt-4 text-gray-300">Loading leaderboard...</p>
            </div>
          ) : leaderboard.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-gray-400">No entries yet. Be the first!</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-crown-gold">
                    <th className="px-4 py-3 text-left text-crown-gold">Rank</th>
                    <th className="px-4 py-3 text-left text-crown-gold">Player</th>
                    <th className="px-4 py-3 text-left text-crown-gold">Country</th>
                    <th className="px-4 py-3 text-right text-crown-gold">
                      {mode === 'fastest_total' ? 'Time' : 'Stage'}
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {leaderboard.map((entry) => (
                    <tr
                      key={entry.user_id}
                      className="border-b border-gray-700 hover:bg-crown-dark transition-colors"
                    >
                      <td className={`px-4 py-3 font-bold ${getRankColor(entry.rank)}`}>
                        {getRankMedal(entry.rank)}
                      </td>
                      <td className="px-4 py-3">{entry.display_name}</td>
                      <td className="px-4 py-3 text-gray-300">
                        {entry.country_code}
                      </td>
                      <td className="px-4 py-3 text-right font-mono">
                        {mode === 'fastest_total'
                          ? formatTime(entry.score)
                          : `Stage ${entry.stage || entry.score}`}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        <footer className="text-center text-gray-400 text-sm">
          <p>Rescue your kin. Reclaim your throne. One stage at a time.</p>
        </footer>
      </div>
    </div>
  )
}

export default App
