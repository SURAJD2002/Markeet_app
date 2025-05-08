// import React from 'react';
// import { FaUserCircle, FaMapMarkerAlt, FaInstagram, FaYoutube, FaFacebook, FaSearch } from 'react-icons/fa';
// import { SiTiktok } from 'react-icons/si';
// import '../styles/InfluencerSearchPage.css';

// function InfluencerSearchPage() {
//   return (
//     <div className="influencer-search-page">
//       {/* TOP NAVIGATION */}
//       <header className="top-nav">
//         <div className="brand-logo">BrandConnect</div>
//         <nav className="nav-links">
//           <a href="#dashboard">Dashboard</a>
//           <a href="#campaigns">Campaigns</a>
//           <a href="#search" className="active">Search Influencers</a>
//           <a href="#analytics">Analytics</a>
//         </nav>
//         <div className="user-profile">
//           <FaUserCircle size={24} />
//         </div>
//       </header>

//       {/* SEARCH BAR */}
//       <div className="search-bar">
//         <input
//           type="text"
//           placeholder="Search influencers by name, niche, or location"
//           className="search-input"
//         />
//         <button className="search-button">
//           <FaSearch className="icon" />
//           Search
//         </button>
//       </div>

//       <div className="main-content">
//         {/* SIDEBAR FILTERS */}
//         <aside className="filters-sidebar">
//           <h3>Filters</h3>

//           {/* Location */}
//           <div className="filter-group">
//             <label htmlFor="locationSelect" className="filter-label">Location</label>
//             <select id="locationSelect" className="filter-select">
//               <option>All Locations</option>
//               <option>Los Angeles, CA</option>
//               <option>New York, NY</option>
//               <option>London, UK</option>
//               <option>Toronto, CA</option>
//             </select>
//           </div>

//           {/* Platforms */}
//           <div className="filter-group">
//             <span className="filter-label">Platforms</span>
//             <div className="checkbox-list">
//               <label>
//                 <input type="checkbox" />
//                 <FaInstagram className="icon" /> Instagram
//               </label>
//               <label>
//                 <input type="checkbox" />
//                 <SiTiktok className="icon" /> TikTok
//               </label>
//               <label>
//                 <input type="checkbox" />
//                 <FaYoutube className="icon" /> YouTube
//               </label>
//               <label>
//                 <input type="checkbox" />
//                 <FaFacebook className="icon" /> Facebook
//               </label>
//             </div>
//           </div>

//           {/* Follower Count */}
//           <div className="filter-group">
//             <span className="filter-label">Follower Count</span>
//             <div className="checkbox-list">
//               <label>
//                 <input type="checkbox" />
//                 1K - 10K
//               </label>
//               <label>
//                 <input type="checkbox" />
//                 10K - 50K
//               </label>
//               <label>
//                 <input type="checkbox" />
//                 50K - 100K
//               </label>
//               <label>
//                 <input type="checkbox" />
//                 100K - 500K
//               </label>
//               <label>
//                 <input type="checkbox" />
//                 500K+
//               </label>
//             </div>
//           </div>

//           {/* Services */}
//           <div className="filter-group">
//             <span className="filter-label">Services</span>
//             <div className="checkbox-list">
//               <label>
//                 <input type="checkbox" />
//                 Photo Content
//               </label>
//               <label>
//                 <input type="checkbox" />
//                 Video Content
//               </label>
//               <label>
//                 <input type="checkbox" />
//                 Story Posts
//               </label>
//             </div>
//           </div>
//         </aside>

//         {/* INFLUENCER CARDS */}
//         <section className="influencer-cards-section">
//           {/* 1. Sarah Johnson */}
//           <div className="influencer-card">
//             <div className="influencer-avatar">
//               {/* Or <img src="..." alt="Influencer" /> if you have a real photo */}
//               <FaUserCircle size={40} />
//             </div>
//             <div className="influencer-info">
//               <h4>Sarah Johnson</h4>
//               <p className="influencer-location">
//                 <FaMapMarkerAlt className="icon" /> Los Angeles, CA
//               </p>
//               <p className="influencer-followers">24.5K Followers</p>
//             </div>
//             <div className="influencer-actions">
//               <button className="view-profile-btn">View Profile</button>
//               <button className="invite-btn">Invite to Campaign</button>
//             </div>
//           </div>

//           {/* 2. Mike Chen */}
//           <div className="influencer-card">
//             <div className="influencer-avatar">
//               <FaUserCircle size={40} />
//             </div>
//             <div className="influencer-info">
//               <h4>Mike Chen</h4>
//               <p className="influencer-location">
//                 <FaMapMarkerAlt className="icon" /> New York, NY
//               </p>
//               <p className="influencer-followers">520K Followers</p>
//             </div>
//             <div className="influencer-actions">
//               <button className="view-profile-btn">View Profile</button>
//               <button className="invite-btn">Invite to Campaign</button>
//             </div>
//           </div>

//           {/* 3. Emma Wilson */}
//           <div className="influencer-card">
//             <div className="influencer-avatar">
//               <FaUserCircle size={40} />
//             </div>
//             <div className="influencer-info">
//               <h4>Emma Wilson</h4>
//               <p className="influencer-location">
//                 <FaMapMarkerAlt className="icon" /> London, UK
//               </p>
//               <p className="influencer-followers">800K Followers</p>
//             </div>
//             <div className="influencer-actions">
//               <button className="view-profile-btn">View Profile</button>
//               <button className="invite-btn">Invite to Campaign</button>
//             </div>
//           </div>

//           {/* 4. David Park */}
//           <div className="influencer-card">
//             <div className="influencer-avatar">
//               <FaUserCircle size={40} />
//             </div>
//             <div className="influencer-info">
//               <h4>David Park</h4>
//               <p className="influencer-location">
//                 <FaMapMarkerAlt className="icon" /> Toronto, CA
//               </p>
//               <p className="influencer-followers">125K Followers</p>
//             </div>
//             <div className="influencer-actions">
//               <button className="view-profile-btn">View Profile</button>
//               <button className="invite-btn">Invite to Campaign</button>
//             </div>
//           </div>
//         </section>
//       </div>
//     </div>
//   );
// }

// export default InfluencerSearchPage;


import React, { useState } from 'react';
import { FaSearch, FaMapMarkerAlt, FaUserCircle } from 'react-icons/fa';
import { FaInstagram, FaYoutube } from 'react-icons/fa';
import { SiTiktok } from 'react-icons/si';
import '../styles/InfluencerSearchPage.css';

function InfluencerSearchPage() {
  const [searchQuery, setSearchQuery] = useState('');

  const influencers = [
    { name: 'Sarah Johnson', location: 'Los Angeles, CA', followers: '24.5K', platforms: ['instagram', 'tiktok'] },
    { name: 'Mike Chen', location: 'New York, NY', followers: '520K', platforms: ['youtube'] },
    { name: 'Emma Wilson', location: 'London, UK', followers: '890K', platforms: ['tiktok'] },
    { name: 'David Park', location: 'Toronto, CA', followers: '125K', platforms: ['instagram'] },
  ];

  return (
    <div className="influencer-search-page">
      {/* TOP NAVIGATION */}
      <header className="top-nav">
        <div className="brand-logo">BrandConnect</div>
        <nav className="nav-links">
          <a href="#dashboard">Dashboard</a>
          <a href="#campaigns">Campaigns</a>
          <a href="#search" className="active">Search Influencers</a>
          <a href="#analytics">Analytics</a>
        </nav>
        <div className="user-profile">
          <FaUserCircle size={24} />
        </div>
      </header>

      {/* SEARCH BAR */}
      <div className="search-bar">
        <FaSearch className="search-icon" />
        <input
          type="text"
          placeholder="Search influencers by name, niche, or location"
          className="search-input"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
        <button className="search-btn">Search</button>
      </div>

      <div className="main-content">
        {/* SIDEBAR FILTERS */}
        <aside className="filters-sidebar">
          <h3>Filters</h3>
          <div className="filter-group">
            <label>Location</label>
            <select className="filter-select">
              <option>All Locations</option>
              <option>Los Angeles, CA</option>
              <option>New York, NY</option>
              <option>London, UK</option>
              <option>Toronto, CA</option>
            </select>
          </div>

          <div className="filter-group">
            <label>Platforms</label>
            <div className="checkbox-list">
              <label>
                <input type="checkbox" />
                <FaInstagram className="icon" /> Instagram
              </label>
              <label>
                <input type="checkbox" />
                <SiTiktok className="icon" /> TikTok
              </label>
              <label>
                <input type="checkbox" />
                <FaYoutube className="icon" /> YouTube
              </label>
            </div>
          </div>

          <div className="filter-group">
            <label>Follower Count</label>
            <div className="checkbox-list">
              <label>
                <input type="checkbox" /> 0k - 10k
              </label>
              <label>
                <input type="checkbox" /> 10k - 50k
              </label>
              <label>
                <input type="checkbox" /> 50k - 100k
              </label>
              <label>
                <input type="checkbox" /> 100k+
              </label>
            </div>
          </div>

          <div className="filter-group">
            <label>Services</label>
            <div className="checkbox-list">
              <label>
                <input type="checkbox" /> Photo Content
              </label>
              <label>
                <input type="checkbox" /> Video Content
              </label>
              <label>
                <input type="checkbox" /> Story Posts
              </label>
            </div>
          </div>
        </aside>

        {/* INFLUENCER CARDS */}
        <section className="influencer-cards-section">
          {influencers.map((influencer, index) => (
            <div className="influencer-card" key={index}>
              <div className="influencer-avatar">
                <img
                  src={`https://i.pravatar.cc/100?img=${index + 1}`}
                  alt={influencer.name}
                  className="avatar-img"
                />
              </div>
              <div className="influencer-info">
                <h4>{influencer.name}</h4>
                <p className="influencer-location">
                  <FaMapMarkerAlt className="icon" /> {influencer.location}
                </p>
                <p className="influencer-followers">{influencer.followers} Followers</p>
                <div className="influencer-platforms">
                  {influencer.platforms.includes('instagram') && <FaInstagram className="platform-icon" />}
                  {influencer.platforms.includes('tiktok') && <SiTiktok className="platform-icon" />}
                  {influencer.platforms.includes('youtube') && <FaYoutube className="platform-icon" />}
                </div>
              </div>
              <div className="influencer-actions">
                <button className="view-profile-btn">View Profile</button>
                <button className="invite-btn">Invite to Campaign</button>
              </div>
            </div>
          ))}
        </section>
      </div>
    </div>
  );
}

export default InfluencerSearchPage;