function NavBar() {
  const path = window.location.pathname

  const linkStyle = (active: boolean) => ({
    fontSize: '14px',
    color: active ? '#2563eb' : '#6b7280',
    textDecoration: 'none' as const,
    fontWeight: '500' as const
  })

  return (
    <nav style={styles.nav}>
      <div style={styles.brand}>Remote CarePro</div>
      <div style={styles.links}>
        <a href="/patients" style={linkStyle(path === '/patients')}>Patients</a>
        <a href="/cases/case-001/medications/list" style={linkStyle(path === '/cases/case-001/medications/list')}>Medications</a>
        <a href="/cases/case-001/recommendations/list" style={linkStyle(path === '/cases/case-001/recommendations/list')}>Recommendations</a>
        <button
          style={styles.logout}
          onClick={() => {
            localStorage.removeItem('token')
            localStorage.removeItem('role')
            window.location.href = '/login'
          }}
        >
          Log out
        </button>
      </div>
    </nav>
  )
}

const styles = {
  nav: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '0 32px',
    height: '56px',
    backgroundColor: '#ffffff',
    borderBottom: '1px solid #e5e7eb',
    position: 'sticky' as const,
    top: 0,
    zIndex: 100
  },
  brand: {
    fontSize: '16px',
    fontWeight: '600' as const,
    color: '#111827'
  },
  links: {
    display: 'flex',
    alignItems: 'center',
    gap: '24px'
  },
  logout: {
    padding: '6px 14px',
    backgroundColor: '#f9fafb',
    color: '#6b7280',
    border: '1px solid #e5e7eb',
    borderRadius: '8px',
    fontSize: '13px',
    cursor: 'pointer'
  }
}

export default NavBar
