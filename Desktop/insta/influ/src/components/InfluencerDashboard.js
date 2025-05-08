// import React from 'react';
// import '../styles/InfluencerDashboard.css';

// function InfluencerDashboard() {
//   return (
//     <div className="dashboard-container">
//       {/* SIDEBAR */}
//       <aside className="sidebar">
//         <div className="user-info">
//           {/* Placeholder for user avatar or icon */}
//           <div className="avatar">SW</div>
//           <h3>Sarah Wilson</h3>
//           <p className="user-title">Beauty & Lifestyle</p>
//         </div>

//         <nav className="sidebar-nav">
//           <ul>
//             <li>My Profile</li>
//             <li>Linked Accounts</li>
//             <li>Campaigns</li>
//             <li>Calendar</li>
//             <li>Analytics</li>
//           </ul>
//         </nav>
//       </aside>

//       {/* MAIN DASHBOARD AREA */}
//       <main className="dashboard-main">
//         <div className="dashboard-header">
//           <h2>Welcome back, Sarah!</h2>
//           <p>Here's what's happening with your influence today</p>
//         </div>

//         {/* STATS CARDS */}
//         <div className="stats-row">
//           <div className="stat-card">
//             <h4>Pending Campaigns</h4>
//             <p className="stat-value">12</p>
//           </div>
//           <div className="stat-card">
//             <h4>Applications</h4>
//             <p className="stat-value">15</p>
//           </div>
//           <div className="stat-card">
//             <h4>Social Growth</h4>
//             <p className="stat-value">+2.4k</p>
//           </div>
//         </div>

//         {/* QUICK-ACTION BUTTONS */}
//         <div className="actions-row">
//           <button className="edit-profile-btn">Edit Profile</button>
//           <button className="link-accounts-btn">Link Social Accounts</button>
//         </div>

//         {/* ACTIVE CAMPAIGNS */}
//         <section className="campaigns-section">
//           <h3>Active Campaigns</h3>
//           <div className="campaign-card">
//             <div className="campaign-info">
//               <h4>Summer Collection 2025</h4>
//               <p className="campaign-subtitle">Fashion Brand Partnership</p>
//               <p className="campaign-date">Due: July 15, 2025</p>
//             </div>
//             <span className="campaign-status active">Active</span>
//           </div>

//           <div className="campaign-card">
//             <div className="campaign-info">
//               <h4>Beauty Tutorial Series</h4>
//               <p className="campaign-subtitle">Cosmetics Brand Partnership</p>
//               <p className="campaign-date">Due: July 25, 2025</p>
//             </div>
//             <span className="campaign-status pending">Pending</span>
//           </div>

//           <div className="campaign-card">
//             <div className="campaign-info">
//               <h4>Lifestyle Vlog Series</h4>
//               <p className="campaign-subtitle">Lifestyle Brand Partnership</p>
//               <p className="campaign-date">Due: June 20, 2025</p>
//             </div>
//             <span className="campaign-status completed">Completed</span>
//           </div>
//         </section>
//       </main>
//     </div>
//   );
// }

// export default InfluencerDashboard;



// import React from 'react';
// // Import React Icons (example: Font Awesome icons)
// import { FaUserCircle, FaEdit, FaLink } from 'react-icons/fa';
// import '../styles/InfluencerDashboard.css';

// function InfluencerDashboard() {
//   return (
//     <div className="dashboard-container">
//       {/* SIDEBAR */}
//       <aside className="sidebar">
//         <div className="user-info">
//           <div className="avatar">
//             <FaUserCircle size={48} />
//           </div>
//           <h3>Sarah Wilson</h3>
//           <p className="user-title">Beauty & Lifestyle</p>
//         </div>

//         <nav className="sidebar-nav">
//           <ul>
//             <li>My Profile</li>
//             <li>Linked Accounts</li>
//             <li>Campaigns</li>
//             <li>Calendar</li>
//             <li>Analytics</li>
//           </ul>
//         </nav>
//       </aside>

//       {/* MAIN DASHBOARD AREA */}
//       <main className="dashboard-main">
//         <div className="dashboard-header">
//           <h2>Welcome back, Sarah!</h2>
//           <p>Here's what's happening with your influence today</p>
//         </div>

//         {/* STATS CARDS */}
//         <div className="stats-row">
//           <div className="stat-card">
//             <h4>Pending Campaigns</h4>
//             <p className="stat-value">12</p>
//           </div>
//           <div className="stat-card">
//             <h4>Applications</h4>
//             <p className="stat-value">15</p>
//           </div>
//           <div className="stat-card">
//             <h4>Social Growth</h4>
//             <p className="stat-value">+2.4k</p>
//           </div>
//         </div>

//         {/* QUICK-ACTION BUTTONS */}
//         <div className="actions-row">
//           <button className="edit-profile-btn">
//             <FaEdit className="button-icon" />
//             Edit Profile
//           </button>
//           <button className="link-accounts-btn">
//             <FaLink className="button-icon" />
//             Link Social Accounts
//           </button>
//         </div>

//         {/* ACTIVE CAMPAIGNS */}
//         <section className="campaigns-section">
//           <h3>Active Campaigns</h3>

//           {/* Campaign 1 */}
//           <div className="campaign-card">
//             <div className="campaign-info">
//               <h4>Summer Collection 2025</h4>
//               <p className="campaign-subtitle">Fashion Brand Partnership</p>
//               <p className="campaign-date">Due: July 15, 2025</p>
//             </div>
//             <span className="campaign-status active">Active</span>
//           </div>

//           {/* Campaign 2 */}
//           <div className="campaign-card">
//             <div className="campaign-info">
//               <h4>Beauty Tutorial Series</h4>
//               <p className="campaign-subtitle">Cosmetics Brand Partnership</p>
//               <p className="campaign-date">Due: July 25, 2025</p>
//             </div>
//             <span className="campaign-status pending">Pending</span>
//           </div>

//           {/* Campaign 3 */}
//           <div className="campaign-card">
//             <div className="campaign-info">
//               <h4>Lifestyle Vlog Series</h4>
//               <p className="campaign-subtitle">Lifestyle Brand Partnership</p>
//               <p className="campaign-date">Due: June 20, 2025</p>
//             </div>
//             <span className="campaign-status completed">Completed</span>
//           </div>
//         </section>
//       </main>
//     </div>
//   );
// }

// export default InfluencerDashboard;




import React from 'react';
import {
  FaUserCircle,
  FaEdit,
  FaLink,
  FaInstagram,
  FaHome
} from 'react-icons/fa';
import { SiTiktok } from 'react-icons/si';
import '../styles/InfluencerDashboard.css';

function InfluencerDashboard() {
  return (
    <div className="dashboard-container">
      {/* SIDEBAR */}
      <aside className="sidebar">
        <div className="user-info">
          <div className="avatar">
            <FaUserCircle size={48} />
          </div>
          <h3>Sarah Wilson</h3>
          <p className="user-title">Beauty & Lifestyle</p>
        </div>

        <nav className="sidebar-nav">
          <ul>
            <li>My Profile</li>
            <li>Linked Accounts</li>
            <li>Campaigns</li>
            <li>Calendar</li>
            <li>Analytics</li>
          </ul>
        </nav>
      </aside>

      {/* MAIN DASHBOARD AREA */}
      <main className="dashboard-main">
        <div className="dashboard-header">
          <h2>Welcome back, Sarah!</h2>
          <p>Here's what's happening with your influence today</p>
        </div>

        {/* STATS CARDS */}
        <div className="stats-row">
          <div className="stat-card">
            <h4>Pending Campaigns</h4>
            <p className="stat-value">12</p>
          </div>
          <div className="stat-card">
            <h4>Applications</h4>
            <p className="stat-value">15</p>
          </div>
          <div className="stat-card">
            <h4>Social Growth</h4>
            <p className="stat-value">+2.4k</p>
          </div>
        </div>

        {/* QUICK-ACTION BUTTONS */}
        <div className="actions-row">
          <button className="edit-profile-btn">
            <FaEdit className="button-icon" />
            Edit Profile
          </button>
          <button className="link-accounts-btn">
            <FaLink className="button-icon" />
            Link Social Accounts
          </button>
        </div>

        {/* ACTIVE CAMPAIGNS */}
        <section className="campaigns-section">
          <h3>Active Campaigns</h3>

          {/* Campaign 1: Instagram Icon */}
          <div className="campaign-card">
            <div className="campaign-info">
              <div className="campaign-header">
                <FaInstagram className="campaign-platform-icon" size={20} />
                <h4>Summer Collection 2025</h4>
              </div>
              <p className="campaign-subtitle">Fashion Brand Campaign</p>
              <p className="campaign-date">Due: July 15, 2025</p>
            </div>
            <span className="campaign-status active">Active</span>
          </div>

          {/* Campaign 2: TikTok Icon */}
          <div className="campaign-card">
            <div className="campaign-info">
              <div className="campaign-header">
                <SiTiktok className="campaign-platform-icon" size={20} />
                <h4>Beauty Tutorial Series</h4>
              </div>
              <p className="campaign-subtitle">Cosmetics Brand Partnership</p>
              <p className="campaign-date">Due: August 1, 2025</p>
            </div>
            <span className="campaign-status pending">Pending</span>
          </div>

          {/* Campaign 3: Home Icon */}
          <div className="campaign-card">
            <div className="campaign-info">
              <div className="campaign-header">
                <FaHome className="campaign-platform-icon" size={20} />
                <h4>Lifestyle Vlog Series</h4>
              </div>
              <p className="campaign-subtitle">Home Decor Brand</p>
              <p className="campaign-date">Completed: June 30, 2025</p>
            </div>
            <span className="campaign-status completed">Completed</span>
          </div>
        </section>
      </main>
    </div>
  );
}

export default InfluencerDashboard;
