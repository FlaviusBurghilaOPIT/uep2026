function NavBar() {
  const path = window.location.pathname

  const linkStyle = (active: boolean) => ({
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    padding: '10px 16px',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '500' as const,
    color: active ? '#2563eb' : '#6b7280',
    backgroundColor: active ? '#eff6ff' : 'transparent',
    textDecoration: 'none' as const,
    cursor: 'pointer'
  })

  return (
    <div style={styles.sidebar}>
      {/* Brand */}
      <div style={styles.brand}>
        <span style={styles.brandPlus}>+</span> CarePro
      </div>

      {/* Nav links */}
      <div style={styles.nav}>
        <a href="/patients" style={linkStyle(path === '/patients')}>
          <span>👤</span> Patients
        </a>
        <a href="/cases/new" style={linkStyle(path === '/cases/new')}>
          <span>📋</span> New Case
        </a>
        <a href="/cases/case-001/medications/list" style={linkStyle(path.includes('medications'))}>
          <span>💊</span> Medications
        </a>
        <a href="/cases/case-001/recommendations/list" style={linkStyle(path.includes('recommendations'))}>
          <span>📝</span> Recommendations
        </a>
      </div>

      {/* Bottom section */}
      <div style={styles.bottom}>
        <div style={styles.divider} />
        <button
          style={styles.logout}
          onClick={() => {
            localStorage.removeItem('token')
            localStorage.removeItem('role')
            window.location.href = '/login'
          }}
        >
          <span>🚪</span> Log out
        </button>
        <div style={styles.userCard}>
          <div style={styles.avatar}>DR</div>
          <div>
            <div style={styles.userName}>Dr. Clinician</div>
            <div style={styles.userRole}>Surgeon</div>
          </div>
        </div>
      </div>
    </div>
  )
}

const styles = {
  sidebar: {
    width: '220px',
    minHeight: '100vh',
    backgroundColor: '#ffffff',
    borderRight: '1px solid #e5e7eb',
    display: 'flex',
    flexDirection: 'column' as const,
    padding: '24px 16px',
    position: 'fixed' as const,
    top: 0,
    left: 0,
    zIndex: 100
  },
  brand: {
    fontSize: '20px',
    fontWeight: '700' as const,
    color: '#111827',
    marginBottom: '32px',
    paddingLeft: '8px'
  },
  brandPlus: {
    color: '#2563eb'
  },
  nav: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '4px',
    flex: 1
  },
  bottom: {
    display: 'flex',
    flexDirection: 'column' as const,
    gap: '12px'
  },
  divider: {
    height: '1px',
    backgroundColor: '#e5e7eb',
    margin: '8px 0'
  },
  logout: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    padding: '10px 16px',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: '500' as const,
    color: '#6b7280',
    backgroundColor: 'transparent',
    border: 'none',
    cursor: 'pointer',
    width: '100%',
    textAlign: 'left' as const
  },
  userCard: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px',
    padding: '10px 8px',
    borderRadius: '8px',
    backgroundColor: '#f9fafb'
  },
  avatar: {
    width: '36px',
    height: '36px',
    borderRadius: '50%',
    backgroundColor: '#2563eb',
    color: '#ffffff',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: '12px',
    fontWeight: '600' as const,
    flexShrink: 0
  },
  userName: {
    fontSize: '13px',
    fontWeight: '500' as const,
    color: '#111827'
  },
  userRole: {
    fontSize: '11px',
    color: '#6b7280'
  }
}

export default NavBar