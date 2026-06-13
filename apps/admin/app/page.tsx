const metrics = [
  ['Schools', '10'],
  ['Active Trips', '0'],
  ['Buses', '0'],
  ['Students', '0'],
];

export default function Home() {
  return (
    <main
      style={{
        maxWidth: 1120,
        margin: '0 auto',
        padding: '32px 20px',
      }}
    >
      <header style={{ marginBottom: 28 }}>
        <p style={{ color: 'var(--muted)', margin: '0 0 8px' }}>SafeRoute Admin</p>
        <h1 style={{ fontSize: 34, lineHeight: 1.15, margin: 0 }}>
          School transport safety dashboard
        </h1>
      </header>

      <section
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 16,
        }}
      >
        {metrics.map(([label, value]) => (
          <article
            key={label}
            style={{
              background: 'var(--panel)',
              border: '1px solid var(--line)',
              borderRadius: 8,
              padding: 18,
            }}
          >
            <div style={{ color: 'var(--muted)', fontSize: 14 }}>{label}</div>
            <strong style={{ display: 'block', fontSize: 30, marginTop: 8 }}>{value}</strong>
          </article>
        ))}
      </section>
    </main>
  );
}

