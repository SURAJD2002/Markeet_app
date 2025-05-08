// import React from 'react';
// import { FaBell, FaEnvelope, FaPlus } from 'react-icons/fa';
// import '../styles/BrandDashboard.css';

// function BrandDashboard() {
//   return (
//     <div className="brand-dashboard">
//       {/* SIDEBAR */}
//       <aside className="sidebar">
//         <div className="brand-logo">Brand Logo</div>
//         <nav className="sidebar-nav">
//           <ul>
//             <li>My Campaigns</li>
//             <li>Hire an Influencer</li>
//             <li>Search Creators</li>
//             <li>Calendar</li>
//             <li>Analytics</li>
//           </ul>
//         </nav>
//       </aside>

//       {/* MAIN CONTENT */}
//       <main className="main-content">
//         {/* TOP BAR */}
//         <div className="topbar">
//           <h2>Brand Dashboard</h2>
//           <div className="topbar-icons">
//             <FaBell className="icon" />
//             <FaEnvelope className="icon" />
//             {/* Optional: user profile or avatar can go here */}
//           </div>
//         </div>

//         {/* STATS AND NEW CAMPAIGN BUTTON */}
//         <div className="stats-section">
//           <div className="stat-card">
//             <p className="stat-title">Active Campaigns</p>
//             <p className="stat-value">12</p>
//           </div>
//           <div className="stat-card">
//             <p className="stat-title">Total Reach</p>
//             <p className="stat-value">2.4M</p>
//           </div>
//           <div className="stat-card">
//             <p className="stat-title">Engagement Rate</p>
//             <p className="stat-value">4.8%</p>
//           </div>
//           <div className="stat-card">
//             <p className="stat-title">Budget Spent</p>
//             <p className="stat-value">$45,987</p>
//           </div>

//           <button className="new-campaign-btn">
//             <FaPlus className="plus-icon" /> Create New Campaign
//           </button>
//         </div>

//         {/* CURRENT CAMPAIGNS */}
//         <section className="current-campaigns">
//           <h3>Current Campaigns</h3>
//           <div className="campaigns-header">
//             <span>Campaign</span>
//             <span>Status</span>
//             <span>Influencers</span>
//             <span>Budget</span>
//             <span>Performance</span>
//           </div>

//           <div className="campaign-row">
//             <div className="campaign-cell">Summer Collection 2025</div>
//             <div className="campaign-cell active">Active</div>
//             <div className="campaign-cell">12</div>
//             <div className="campaign-cell">$12,000</div>
//             <div className="campaign-cell">+24%</div>
//           </div>

//           <div className="campaign-row">
//             <div className="campaign-cell">Spring Launch</div>
//             <div className="campaign-cell pending">Pending</div>
//             <div className="campaign-cell">8</div>
//             <div className="campaign-cell">$5,000</div>
//             <div className="campaign-cell">+10%</div>
//           </div>

//           <div className="campaign-row">
//             <div className="campaign-cell">Winter Sale</div>
//             <div className="campaign-cell completed">Completed</div>
//             <div className="campaign-cell">15</div>
//             <div className="campaign-cell">$9,500</div>
//             <div className="campaign-cell">-3%</div>
//           </div>
//         </section>

//         {/* NOTIFICATIONS AND MESSAGES */}
//         <div className="bottom-row">
//           <div className="notifications-panel">
//             <h4>Recent Notifications</h4>
//             <ul>
//               <li>New influencer application received</li>
//               <li>Payment invoice #123 was sent</li>
//               <li>2 new messages in your inbox</li>
//             </ul>
//           </div>
//           <div className="messages-panel">
//             <h4>Recent Messages</h4>
//             <div className="message">
//               <p className="message-sender">Sarah Johnson</p>
//               <p className="message-snippet">“Hey, I'm interested in collaborating...”</p>
//               <span className="message-time">10:25 AM</span>
//             </div>
//             <div className="message">
//               <p className="message-sender">Mike Peterson</p>
//               <p className="message-snippet">“Let’s discuss the terms for your new campaign...”</p>
//               <span className="message-time">9:10 AM</span>
//             </div>
//           </div>
//         </div>
//       </main>
//     </div>
//   );
// }

// export default BrandDashboard;



// src/components/BrandDashboard.jsx
import React, { useState, useEffect } from 'react';
import { FaBell, FaEnvelope, FaPlus } from 'react-icons/fa';
import { supabase } from '../supabase';
import '../styles/BrandDashboard.css';

function BrandDashboard() {
  const [campaigns, setCampaigns] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    setLoading(true);
    setError(null);

    // 1) Get current user
    const {
      data: { user },
      error: userErr,
    } = await supabase.auth.getUser();
    if (userErr || !user) {
      console.error('Error fetching user:', userErr);
      setError('Could not authenticate. Please log in again.');
      setLoading(false);
      return;
    }
    const brandId = user.id;

    try {
      // 2) Fetch campaigns
      const { data: campData, error: campErr } = await supabase
        .from('campaigns')
        .select('*')
        .eq('brand_id', brandId);
      if (campErr) throw campErr;
      setCampaigns(campData);

      // 3) Fetch notifications (latest 5)
      const { data: notifData, error: notifErr } = await supabase
        .from('notifications')
        .select('*')
        .eq('brand_id', brandId)
        .order('created_at', { ascending: false })
        .limit(5);
      if (notifErr) throw notifErr;
      setNotifications(notifData);

      // 4) Fetch messages (latest 5)
      const { data: msgData, error: msgErr } = await supabase
        .from('messages')
        .select('*')
        .eq('brand_id', brandId)
        .order('sent_at', { ascending: false })
        .limit(5);
      if (msgErr) throw msgErr;
      setMessages(msgData);

    } catch (fetchErr) {
      console.error('Dashboard fetch error:', fetchErr);
      setError('Failed to load dashboard data.');
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div className="dashboard-loading">Loading dashboard…</div>;
  if (error)   return <div className="dashboard-error">Error: {error}</div>;

  return (
    <div className="brand-dashboard">
      {/* SIDEBAR */}
      <aside className="sidebar">
        <div className="brand-logo">Brand Logo</div>
        <nav className="sidebar-nav">
          <ul>
            <li>My Campaigns</li>
            <li>Hire an Influencer</li>
            <li>Search Creators</li>
            <li>Calendar</li>
            <li>Analytics</li>
          </ul>
        </nav>
      </aside>

      {/* MAIN CONTENT */}
      <main className="main-content">
        {/* TOP BAR */}
        <div className="topbar">
          <h2>Brand Dashboard</h2>
          <div className="topbar-icons">
            <FaBell className="icon" />
            <FaEnvelope className="icon" />
          </div>
        </div>

        {/* STATS & NEW CAMPAIGN */}
        <div className="stats-section">
          <div className="stat-card">
            <p className="stat-title">Active Campaigns</p>
            <p className="stat-value">
              {campaigns.filter(c => c.status === 'Active').length}
            </p>
          </div>
          <div className="stat-card">
            <p className="stat-title">Total Reach</p>
            <p className="stat-value">2.4M</p>
          </div>
          <div className="stat-card">
            <p className="stat-title">Engagement Rate</p>
            <p className="stat-value">4.8%</p>
          </div>
          <div className="stat-card">
            <p className="stat-title">Budget Spent</p>
            <p className="stat-value">$45,987</p>
          </div>

          <button className="new-campaign-btn">
            <FaPlus className="plus-icon" /> Create New Campaign
          </button>
        </div>

        {/* CURRENT CAMPAIGNS */}
        <section className="current-campaigns">
          <h3>Current Campaigns</h3>
          <div className="campaigns-header">
            <span>Campaign</span>
            <span>Status</span>
            <span>Influencers</span>
            <span>Budget</span>
            <span>Performance</span>
          </div>

          {campaigns.map(c => (
            <div key={c.id} className="campaign-row">
              <div className="campaign-cell">{c.name}</div>
              <div className={`campaign-cell ${c.status.toLowerCase()}`}>
                {c.status}
              </div>
              <div className="campaign-cell">{c.influencers_count}</div>
              <div className="campaign-cell">${c.budget}</div>
              <div className="campaign-cell">{c.performance}</div>
            </div>
          ))}
        </section>

        {/* NOTIFICATIONS & MESSAGES */}
        <div className="bottom-row">
          <div className="notifications-panel">
            <h4>Recent Notifications</h4>
            <ul>
              {notifications.map(n => (
                <li key={n.id}>{n.message}</li>
              ))}
            </ul>
          </div>
          <div className="messages-panel">
            <h4>Recent Messages</h4>
            {messages.map(m => (
              <div key={m.id} className="message">
                <p className="message-sender">{m.sender_name}</p>
                <p className="message-snippet">{m.snippet}</p>
                <span className="message-time">
                  {new Date(m.sent_at).toLocaleTimeString()}
                </span>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}

export default BrandDashboard;
