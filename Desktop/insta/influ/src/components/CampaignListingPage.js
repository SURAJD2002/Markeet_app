// // import React, { useState, useMemo } from 'react';
// // import {
// //   FaSearch,
// //   FaThList,
// //   FaFilter,
// //   FaBell,
// //   FaInstagram,
// //   FaTiktok,
// //   FaYoutube,
// //   FaTag,
// //   FaTimes,
// //   FaTachometerAlt,
// //   FaBullhorn,
// //   FaChartLine,
// //   FaWallet,
// //   FaCog,
// // } from 'react-icons/fa';
// // import '../styles/CampaignListingPage.css';

// // const campaigns = [
// //   {
// //     id: 1,
// //     title: 'Summer Beauty Campaign',
// //     brand: 'GlamCo Beauty',
// //     image: 'https://via.placeholder.com/300x150?text=Beauty+Campaign',
// //     platform: 'Instagram',
// //     type: 'Story + Post',
// //     budget: '$800 per post',
// //     deadline: 'May 15, 2025',
// //     status: 'open',
// //   },
// //   {
// //     id: 2,
// //     title: 'Fitness Challenge',
// //     brand: 'FitLife Pro',
// //     image: 'https://via.placeholder.com/300x150?text=Fitness+Challenge',
// //     platform: 'TikTok',
// //     type: 'Video Series',
// //     budget: '$1,200 per video',
// //     deadline: 'May 30, 2025',
// //     status: 'open',
// //   },
// //   {
// //     id: 3,
// //     title: 'Tech Review Series',
// //     brand: 'TechGear Pro',
// //     image: 'https://via.placeholder.com/300x150?text=Tech+Review',
// //     platform: 'YouTube',
// //     type: 'Review',
// //     budget: '$2,000 + Product',
// //     deadline: 'June 15, 2025',
// //     status: 'applied',
// //   },
// // ];

// // const initialFilters = [
// //   { id: 'ig', icon: <FaInstagram />, label: 'Instagram' },
// //   { id: 'video', icon: <FaTiktok />, label: 'Video Content' },
// //   { id: 'budget', icon: <FaTag />, label: '$500-1000' },
// // ];

// // const navItems = [
// //   { id: 'dashboard', label: 'Dashboard', icon: <FaTachometerAlt /> },
// //   { id: 'campaigns', label: 'Campaigns', icon: <FaBullhorn /> },
// //   { id: 'analytics', label: 'Analytics', icon: <FaChartLine /> },
// //   { id: 'earnings', label: 'Earnings', icon: <FaWallet /> },
// //   { id: 'settings', label: 'Settings', icon: <FaCog /> },
// // ];

// // export default function CampaignListingPage() {
// //   const [search, setSearch] = useState('');
// //   const [filters, setFilters] = useState(initialFilters);

// //   const filteredList = useMemo(
// //     () =>
// //       campaigns.filter((c) =>
// //         (c.title + c.brand).toLowerCase().includes(search.toLowerCase())
// //       ),
// //     [search]
// //   );

// //   const removeFilter = (id) => setFilters((f) => f.filter((x) => x.id !== id));

// //   return (
// //     <div className="layout">
// //       <aside className="sidebar">
// //         <h1 className="sidebar__logo">InfluenceHub</h1>
// //         <nav className="sidebar__nav">
// //           {navItems.map((item) => (
// //             <div
// //               key={item.id}
// //               className={
// //                 'sidebar__item' +
// //                 (item.id === 'dashboard' ? ' sidebar__item--active' : '')
// //               }
// //             >
// //               <span className="sidebar__icon">{item.icon}</span>
// //               {item.label}
// //             </div>
// //           ))}
// //         </nav>
// //       </aside>

// //       <main className="main">
// //         <header className="main__header">
// //           <div>
// //             <h2 className="header__title">Available Campaigns</h2>
// //             <p className="header__subtitle">
// //               Find and apply to campaigns that match your profile
// //             </p>
// //           </div>
// //           <div className="header__actions">
// //             <FaBell className="action__icon" />
// //             <span className="action__badge">3</span>
// //             <img
// //               className="action__avatar"
// //               src="https://via.placeholder.com/40"
// //               alt="User"
// //             />
// //           </div>
// //         </header>

// //         <section className="controls">
// //           <div className="controls__row controls__row--search">
// //             <div className="search">
// //               <FaSearch className="search__icon" />
// //               <input
// //                 className="search__input"
// //                 placeholder="Search campaigns..."
// //                 value={search}
// //                 onChange={(e) => setSearch(e.target.value)}
// //               />
// //             </div>
// //           </div>

// //           <div className="controls__row controls__row--actions">
// //             <button className="btn btn--list">
// //               <FaThList /> List View
// //             </button>
// //             <button className="btn btn--filter">
// //               <FaFilter /> Filters
// //             </button>
// //           </div>

// //           <div className="controls__row controls__row--tags">
// //             {filters.map((f) => (
// //               <span key={f.id} className="tag">
// //                 {f.icon}
// //                 {f.label}
// //                 <FaTimes
// //                   className="tag__remove"
// //                   onClick={() => removeFilter(f.id)}
// //                 />
// //               </span>
// //             ))}
// //           </div>
// //         </section>

// //         <section className="grid">
// //           {filteredList.map((c) => (
// //             <div key={c.id} className="card">
// //               <div className="card__image">
// //                 <img src={c.image} alt={c.title} />
// //                 <span className={`card__status card__status--${c.status}`}>
// //                   {c.status}
// //                 </span>
// //               </div>
// //               <div className="card__body">
// //                 <h3 className="card__title">{c.title}</h3>
// //                 <p className="card__brand">{c.brand}</p>
// //                 <ul className="card__meta">
// //                   <li>
// //                     {c.platform} — {c.type}
// //                   </li>
// //                   <li>{c.budget}</li>
// //                   <li>Deadline: {c.deadline}</li>
// //                 </ul>
// //                 <button
// //                   className={
// //                     'btn ' +
// //                     (c.status === 'applied' ? 'btn--disabled' : 'btn--primary')
// //                   }
// //                   disabled={c.status === 'applied'}
// //                 >
// //                   {c.status === 'open' ? 'View Details' : 'Application Pending'}
// //                 </button>
// //               </div>
// //             </div>
// //           ))}
// //         </section>
// //       </main>
// //     </div>
// //   );
// // }



// import React, { useState, useMemo } from 'react';
// import {
//   FaSearch,
//   FaThList,
//   FaFilter,
//   FaBell,
//   FaInstagram,
//   FaTiktok,
//   FaYoutube,
//   FaTag,
//   FaTimes,
//   FaTachometerAlt,
//   FaBullhorn,
//   FaChartLine,
//   FaWallet,
//   FaCog,
// } from 'react-icons/fa';
// import '../styles/CampaignListingPage.css';

// const campaigns = [
//   {
//     id: 1,
//     title: 'Summer Beauty Campaign',
//     brand: 'GlamCo Beauty',
//     image: 'https://images.unsplash.com/photo-1600585154347-be6161a56a0c?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=150&q=80', // Beauty products
//     platform: 'Instagram',
//     type: 'Story + Post',
//     budget: '$800 per post',
//     deadline: 'May 15, 2025',
//     status: 'open',
//   },
//   {
//     id: 2,
//     title: 'Fitness Challenge',
//     brand: 'FitLife Pro',
//     image: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=150&q=80', // Fitness gym
//     platform: 'TikTok',
//     type: 'Video Series',
//     budget: '$1,200 per video',
//     deadline: 'May 30, 2025',
//     status: 'open',
//   },
//   {
//     id: 3,
//     title: 'Tech Review Series',
//     brand: 'TechGear Pro',
//     image: 'https://images.unsplash.com/photo-1600585154347-be6161a56a0c?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=150&q=80', // Tech setup
//     platform: 'YouTube',
//     type: 'Review',
//     budget: '$2,000 + Product',
//     deadline: 'June 15, 2025',
//     status: 'applied',
//   },
// ];

// const initialFilters = [
//   { id: 'ig', icon: <FaInstagram />, label: 'Instagram' },
//   { id: 'video', icon: <FaTiktok />, label: 'Video Content' },
//   { id: 'budget', icon: <FaTag />, label: '$500-1000' },
// ];

// const navItems = [
//   { id: 'dashboard', label: 'Dashboard', icon: <FaTachometerAlt /> },
//   { id: 'campaigns', label: 'Campaigns', icon: <FaBullhorn /> },
//   { id: 'analytics', label: 'Analytics', icon: <FaChartLine /> },
//   { id: 'earnings', label: 'Earnings', icon: <FaWallet /> },
//   { id: 'settings', label: 'Settings', icon: <FaCog /> },
// ];

// export default function CampaignListingPage() {
//   const [search, setSearch] = useState('');
//   const [filters, setFilters] = useState(initialFilters);

//   const filteredList = useMemo(
//     () =>
//       campaigns.filter((c) =>
//         (c.title + c.brand).toLowerCase().includes(search.toLowerCase())
//       ),
//     [search]
//   );

//   const removeFilter = (id) => setFilters((f) => f.filter((x) => x.id !== id));

//   return (
//     <div className="layout">
//       <aside className="sidebar">
//         <h1 className="sidebar__logo">InfluenceHub</h1>
//         <nav className="sidebar__nav">
//           {navItems.map((item) => (
//             <div
//               key={item.id}
//               className={
//                 'sidebar__item' +
//                 (item.id === 'dashboard' ? ' sidebar__item--active' : '')
//               }
//             >
//               <span className="sidebar__icon">{item.icon}</span>
//               {item.label}
//             </div>
//           ))}
//         </nav>
//       </aside>

//       <main className="main">
//         <header className="main__header">
//           <div>
//             <h2 className="header__title">Available Campaigns</h2>
//             <p className="header__subtitle">
//               Find and apply to campaigns that match your profile
//             </p>
//           </div>
//           <div className="header__actions">
//             <FaBell className="action__icon" />
//             <span className="action__badge">3</span>
//             <img
//               className="action__avatar"
//               src="https://via.placeholder.com/40"
//               alt="User"
//             />
//           </div>
//         </header>

//         <section className="controls">
//           <div className="controls__row controls__row--search">
//             <div className="search">
//               <FaSearch className="search__icon" />
//               <input
//                 className="search__input"
//                 placeholder="Search campaigns..."
//                 value={search}
//                 onChange={(e) => setSearch(e.target.value)}
//               />
//             </div>
//           </div>

//           <div className="controls__row controls__row--actions">
//             <button className="btn btn--list">
//               <FaThList /> List View
//             </button>
//             <button className="btn btn--filter">
//               <FaFilter /> Filters
//             </button>
//           </div>

//           <div className="controls__row controls__row--tags">
//             {filters.map((f) => (
//               <span key={f.id} className="tag">
//                 {f.icon}
//                 {f.label}
//                 <FaTimes
//                   className="tag__remove"
//                   onClick={() => removeFilter(f.id)}
//                 />
//               </span>
//             ))}
//           </div>
//         </section>

//         <section className="grid">
//           {filteredList.map((c) => (
//             <div key={c.id} className="card">
//               <div className="card__image">
//                 <img src={c.image} alt={c.title} />
//                 <span className={`card__status card__status--${c.status}`}>
//                   {c.status}
//                 </span>
//               </div>
//               <div className="card__body">
//                 <h3 className="card__title">{c.title}</h3>
//                 <p className="card__brand">{c.brand}</p>
//                 <ul className="card__meta">
//                   <li>
//                     {c.platform} — {c.type}
//                   </li>
//                   <li>{c.budget}</li>
//                   <li>Deadline: {c.deadline}</li>
//                 </ul>
//                 <button
//                   className={
//                     'btn ' +
//                     (c.status === 'applied' ? 'btn--disabled' : 'btn--primary')
//                   }
//                   disabled={c.status === 'applied'}
//                 >
//                   {c.status === 'open' ? 'View Details' : 'Application Pending'}
//                 </button>
//               </div>
//             </div>
//           ))}
//         </section>
//       </main>
//     </div>
//   );
// }



import React, { useState, useMemo } from 'react';
import {
  FaSearch,
  FaThList,
  FaFilter,
  FaBell,
  FaInstagram,
  FaTiktok,
  FaYoutube,
  FaTag,
  FaTimes,
} from 'react-icons/fa';
import '../styles/CampaignListingPage.css';

const campaigns = [
  {
    id: 1,
    title: 'Summer Beauty Campaign',
    brand: 'GlamCo Beauty',
    image: 'https://images.unsplash.com/photo-1600585154347-be6161a56a0c?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=150&q=80',
    platform: 'Instagram',
    type: 'Story + Post',
    budget: '$800 per post',
    deadline: 'May 15, 2025',
    status: 'open',
  },
  {
    id: 2,
    title: 'Fitness Challenge',
    brand: 'FitLife Pro',
    image: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=150&q=80',
    platform: 'TikTok',
    type: 'Video Series',
    budget: '$1,200 per video',
    deadline: 'May 30, 2025',
    status: 'open',
  },
  {
    id: 3,
    title: 'Tech Review Series',
    brand: 'TechGear Pro',
    image: 'https://images.unsplash.com/photo-1600585154347-be6161a56a0c?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&h=150&q=80',
    platform: 'YouTube',
    type: 'Review',
    budget: '$2,000 + Product',
    deadline: 'June 15, 2025',
    status: 'applied',
  },
];

const initialFilters = [
  { id: 'ig', icon: <FaInstagram />, label: 'Instagram' },
  { id: 'video', icon: <FaTiktok />, label: 'Video Content' },
  { id: 'budget', icon: <FaTag />, label: '$500-1000' },
];

export default function CampaignListingPage() {
  const [search, setSearch] = useState('');
  const [filters, setFilters] = useState(initialFilters);

  const filteredList = useMemo(
    () =>
      campaigns.filter((c) =>
        (c.title + c.brand).toLowerCase().includes(search.toLowerCase())
      ),
    [search]
  );

  const removeFilter = (id) => setFilters((f) => f.filter((x) => x.id !== id));

  return (
    <div className="layout">
      <main className="main">
        <header className="main__header">
          <div>
            <h2 className="header__title">Available Campaigns</h2>
            <p className="header__subtitle">
              Find and apply to campaigns that match your profile
            </p>
          </div>
          <div className="header__actions">
            <FaBell className="action__icon" />
            <span className="action__badge">3</span>
            <img
              className="action__avatar"
              src="https://via.placeholder.com/40"
              alt="User"
            />
          </div>
        </header>

        <section className="controls">
          <div className="controls__row controls__row--search">
            <div className="search">
              <FaSearch className="search__icon" />
              <input
                className="search__input"
                placeholder="Search campaigns..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
          </div>

          <div className="controls__row controls__row--actions">
            <button className="btn btn--list">
              <FaThList /> List View
            </button>
            <button className="btn btn--filter">
              <FaFilter /> Filters
            </button>
          </div>

          <div className="controls__row controls__row--tags">
            {filters.map((f) => (
              <span key={f.id} className="tag">
                {f.icon}
                {f.label}
                <FaTimes
                  className="tag__remove"
                  onClick={() => removeFilter(f.id)}
                />
              </span>
            ))}
          </div>
        </section>

        <section className="grid">
          {filteredList.map((c) => (
            <div key={c.id} className="card">
              <div className="card__image">
                <img src={c.image} alt={c.title} />
                <span className={`card__status card__status--${c.status}`}>
                  {c.status}
                </span>
              </div>
              <div className="card__body">
                <h3 className="card__title">{c.title}</h3>
                <p className="card__brand">{c.brand}</p>
                <ul className="card__meta">
                  <li>
                    {c.platform} — {c.type}
                  </li>
                  <li>{c.budget}</li>
                  <li>Deadline: {c.deadline}</li>
                </ul>
                <button
                  className={
                    'btn ' +
                    (c.status === 'applied' ? 'btn--disabled' : 'btn--primary')
                  }
                  disabled={c.status === 'applied'}
                >
                  {c.status === 'open' ? 'View Details' : 'Application Pending'}
                </button>
              </div>
            </div>
          ))}
        </section>
      </main>
    </div>
  );
}