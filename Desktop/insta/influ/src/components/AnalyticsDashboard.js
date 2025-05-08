// import React from 'react';
// import { FaUsers, FaChartLine, FaEye, FaBullhorn, FaThumbsUp, FaComment, FaShare, FaCalendarAlt, FaDownload } from 'react-icons/fa';
// import '../styles/AnalyticsDashboard.css';

// function AnalyticsDashboard() {
//   const metrics = [
//     { label: 'Total Followers', value: '124.5K', change: '+2.4% this month', icon: <FaUsers />, color: '#27ae60' },
//     { label: 'Engagement Rate', value: '5.2%', change: '-0.8% this month', icon: <FaChartLine />, color: '#e74c3c' },
//     { label: 'Total Reach', value: '892.1K', change: '+12.3% this month', icon: <FaEye />, color: '#27ae60' },
//     { label: 'Active Campaigns', value: '8', change: '3 ending soon', icon: <FaBullhorn />, color: '#f39c12' },
//   ];

//   const campaigns = [
//     { name: 'Summer Collection', engagement: '8.2%', reach: '245K', roi: '3.4x', status: 'Active', statusColor: '#27ae60' },
//     { name: 'Brand Awareness', engagement: '6.7%', reach: '189K', roi: '2.8x', status: 'Active', statusColor: '#27ae60' },
//     { name: 'Product Launch', engagement: '9.1%', reach: '312K', roi: '4.2x', status: 'Ending Soon', statusColor: '#f39c12' },
//   ];

//   const growth = {
//     newFollowers: '+2,456',
//     unfollows: '-342',
//     netGrowth: '+2,114',
//   };

//   const posts = [
//     { likes: '12.4K', comments: '824', shares: '2.1K' },
//     { likes: '9.8K', comments: '567', shares: '1.5K' },
//     { likes: '8.2K', comments: '434', shares: '987' },
//     { likes: '7.5K', comments: '389', shares: '856' },
//   ];

//   return (
//     <div className="analytics-container">
//       {/* HEADER */}
//       <header className="analytics-header">
//         <h2>Analytics Dashboard</h2>
//         <div className="header-actions">
//           <button className="time-btn">
//             <FaCalendarAlt /> Last 30 Days
//           </button>
//           <button className="export-btn">
//             <FaDownload /> Export
//           </button>
//         </div>
//       </header>

//       {/* METRICS OVERVIEW */}
//       <section className="metrics-overview">
//         {metrics.map((metric, index) => (
//           <div key={index} className="metric-card" style={{ borderLeft: `4px solid ${metric.color}` }}>
//             <div className="metric-icon">{metric.icon}</div>
//             <div className="metric-details">
//               <p className="metric-label">{metric.label}</p>
//               <p className="metric-value">{metric.value}</p>
//               <p className={`metric-change ${metric.change.includes('-') ? 'negative' : 'positive'}`}>
//                 {metric.change}
//               </p>
//             </div>
//           </div>
//         ))}
//       </section>

//       {/* ENGAGEMENT OVERVIEW */}
//       <section className="engagement-overview">
//         <h3>Engagement Overview</h3>
//         <div className="filter-buttons">
//           <button className="filter-btn">Likes</button>
//           <button className="filter-btn">Comments</button>
//           <button className="filter-btn">Reach</button>
//         </div>
//         <div className="engagement-chart">
//           {/* Placeholder for chart (replace with actual chart component if needed) */}
//           <div className="chart-placeholder">Chart Placeholder</div>
//         </div>
//       </section>

//       {/* CAMPAIGN PERFORMANCE & GROWTH TRACKING */}
//       <div className="performance-growth-container">
//         <section className="campaign-performance">
//           <h3>Campaign Performance</h3>
//           {campaigns.map((campaign, index) => (
//             <div key={index} className="campaign-card">
//               <div className="campaign-name">{campaign.name}</div>
//               <div className="campaign-metrics">
//                 <p>Engagement: {campaign.engagement}</p>
//                 <p>Reach: {campaign.reach}</p>
//                 <p>ROI: {campaign.roi}</p>
//               </div>
//               <span className="campaign-status" style={{ backgroundColor: campaign.statusColor }}>
//                 {campaign.status}
//               </span>
//             </div>
//           ))}
//         </section>

//         <section className="growth-tracking">
//           <h3>Growth Tracking</h3>
//           <div className="growth-metrics">
//             <div className="growth-item">
//               <p>New Followers</p>
//               <p className="growth-value positive">{growth.newFollowers}</p>
//             </div>
//             <div className="growth-item">
//               <p>Unfollows</p>
//               <p className="growth-value negative">{growth.unfollows}</p>
//             </div>
//             <div className="growth-item">
//               <p>Net Growth</p>
//               <p className="growth-value positive">{growth.netGrowth}</p>
//             </div>
//           </div>
//         </section>
//       </div>

//       {/* POST PERFORMANCE */}
//       <section className="post-performance">
//         <h3>Post Performance</h3>
//         <div className="post-grid">
//           {posts.map((post, index) => (
//             <div key={index} className="post-card">
//               <div className="post-placeholder"></div>
//               <div className="post-stats">
//                 <p>Likes: {post.likes}</p>
//                 <p>Comments: {post.comments}</p>
//                 <p>Shares: {post.shares}</p>
//               </div>
//             </div>
//           ))}
//         </div>
//       </section>
//     </div>
//   );
// }

// export default AnalyticsDashboard;



import React from 'react';
import { FaUsers, FaChartLine, FaEye, FaBullhorn, FaThumbsUp, FaComment, FaShare, FaCalendarAlt, FaDownload } from 'react-icons/fa';
import '../styles/AnalyticsDashboard.css';

function AnalyticsDashboard() {
  const metrics = [
    { label: 'Total Followers', value: '124.5K', change: '+2.4% this month', icon: <FaUsers />, color: '#27ae60' },
    { label: 'Engagement Rate', value: '5.2%', change: '-0.8% this month', icon: <FaChartLine />, color: '#e74c3c' },
    { label: 'Total Reach', value: '892.1K', change: '+12.3% this month', icon: <FaEye />, color: '#27ae60' },
    { label: 'Active Campaigns', value: '8', change: '3 ending soon', icon: <FaBullhorn />, color: '#f39c12' },
  ];

  const campaigns = [
    { name: 'Summer Collection', engagement: '8.2%', reach: '245K', roi: '3.4x', status: 'Active', statusColor: '#27ae60' },
    { name: 'Brand Awareness', engagement: '6.7%', reach: '189K', roi: '2.8x', status: 'Active', statusColor: '#27ae60' },
    { name: 'Product Launch', engagement: '9.1%', reach: '312K', roi: '4.2x', status: 'Ending Soon', statusColor: '#f39c12' },
  ];

  const growth = {
    newFollowers: '+2,456',
    unfollows: '-342',
    netGrowth: '+2,114',
  };

  const posts = [
    { likes: '12.4K', comments: '824', shares: '2.1K' },
    { likes: '9.8K', comments: '567', shares: '1.5K' },
    { likes: '8.2K', comments: '434', shares: '987' },
    { likes: '7.5K', comments: '389', shares: '856' },
  ];

  return (
    <div className="analytics-container">
      {/* HEADER */}
      <header className="analytics-header">
        <h2>Analytics Dashboard</h2>
        <div className="header-actions">
          <button className="time-btn">
            <FaCalendarAlt /> Last 30 Days
          </button>
          <button className="export-btn">
            <FaDownload /> Export
          </button>
        </div>
      </header>

      {/* METRICS OVERVIEW */}
      <section className="metrics-overview">
        {metrics.map((metric, index) => (
          <div key={index} className="metric-card" style={{ borderLeft: `4px solid ${metric.color}` }}>
            <div className="metric-icon">{metric.icon}</div>
            <div className="metric-details">
              <p className="metric-label">{metric.label}</p>
              <p className="metric-value">{metric.value}</p>
              <p className={`metric-change ${metric.change.includes('-') ? 'negative' : 'positive'}`}>
                {metric.change}
              </p>
            </div>
          </div>
        ))}
      </section>

      {/* ENGAGEMENT OVERVIEW */}
      <section className="engagement-overview">
        <h3>Engagement Overview</h3>
        <div className="filter-buttons">
          <button className="filter-btn">Likes</button>
          <button className="filter-btn">Comments</button>
          <button className="filter-btn">Reach</button>
        </div>
        <div className="engagement-chart">
          {/* Placeholder for chart (replace with actual chart component if needed) */}
          <div className="chart-placeholder">Chart Placeholder</div>
        </div>
      </section>

      {/* CAMPAIGN PERFORMANCE & GROWTH TRACKING */}
      <div className="performance-growth-container">
        <section className="campaign-performance">
          <h3>Campaign Performance</h3>
          {campaigns.map((campaign, index) => (
            <div key={index} className="campaign-card">
              <div className="campaign-name">{campaign.name}</div>
              <div className="campaign-metrics">
                <p>Engagement: {campaign.engagement}</p>
                <p>Reach: {campaign.reach}</p>
                <p>ROI: {campaign.roi}</p>
              </div>
              <span className="campaign-status" style={{ backgroundColor: campaign.statusColor }}>
                {campaign.status}
              </span>
            </div>
          ))}
        </section>

        <section className="growth-tracking">
          <h3>Growth Tracking</h3>
          <div className="growth-metrics">
            <div className="growth-item">
              <p>New Followers</p>
              <p className="growth-value positive">{growth.newFollowers}</p>
            </div>
            <div className="growth-item">
              <p>Unfollows</p>
              <p className="growth-value negative">{growth.unfollows}</p>
            </div>
            <div className="growth-item">
              <p>Net Growth</p>
              <p className="growth-value positive">{growth.netGrowth}</p>
            </div>
          </div>
        </section>
      </div>

      {/* POST PERFORMANCE */}
      <section className="post-performance">
        <h3>Post Performance</h3>
        <div className="post-grid">
          {posts.map((post, index) => (
            <div key={index} className="post-card">
              <div className="post-placeholder"></div>
              <div className="post-stats">
                <p>Likes: {post.likes}</p>
                <p>Comments: {post.comments}</p>
                <p>Shares: {post.shares}</p>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

export default AnalyticsDashboard;