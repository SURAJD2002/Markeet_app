// import React from 'react';
// import { FaMapMarkerAlt, FaUserCircle, FaCamera, FaVideo, FaBullhorn } from 'react-icons/fa';
// import { AiFillStar } from 'react-icons/ai';  // For star ratings
// import '../styles/InfluencerProfilePublic.css';

// function InfluencerProfilePublic() {
//   // Sample data (In a real app, fetch from an API or pass as props)
//   const influencer = {
//     name: 'Sarah Anderson',
//     city: 'Los Angeles, CA',
//     stats: '245K followers · 180K followers · 50K subscribers',
//     photoUrl: '', // Provide a real URL if you have an actual profile photo
//     services: [
//       {
//         icon: <FaCamera />,
//         title: 'Photo Content',
//         description: 'Professional photography for products and brands',
//       },
//       {
//         icon: <FaVideo />,
//         title: 'Video Content',
//         description: 'Engaging video content for social media',
//       },
//       {
//         icon: <FaBullhorn />,
//         title: 'Brand Promotion',
//         description: 'Sponsored posts and brand partnerships',
//       },
//     ],
//     portfolio: [
//       // Replace with actual image URLs
//       'https://via.placeholder.com/400x400?text=Portfolio+1',
//       'https://via.placeholder.com/400x400?text=Portfolio+2',
//       'https://via.placeholder.com/400x400?text=Portfolio+3',
//     ],
//     reviews: [
//       {
//         author: 'John Smith',
//         rating: 5,
//         text: 'Amazing to work with! Very professional and delivered great results for our campaign.',
//       },
//       {
//         author: 'Emma Wilson',
//         rating: 5,
//         text: 'Great engagement rates and very responsive throughout the collaboration.',
//       },
//     ],
//   };

//   // Helper to render star ratings
//   const renderStars = (count) => {
//     const stars = [];
//     for (let i = 0; i < count; i++) {
//       stars.push(<AiFillStar key={i} className="star-icon" />);
//     }
//     return stars;
//   };

//   return (
//     <div className="influencer-public-profile">
//       {/* PROFILE HEADER SECTION */}
//       <div className="profile-hero">
//         <div className="profile-left">
//           {influencer.photoUrl ? (
//             <img src={influencer.photoUrl} alt="Profile" className="profile-photo" />
//           ) : (
//             <FaUserCircle className="profile-icon" />
//           )}
//           <div className="profile-details">
//             <h1 className="profile-name">{influencer.name}</h1>
//             <p className="profile-location">
//               <FaMapMarkerAlt /> {influencer.city}
//             </p>
//             <p className="profile-stats">{influencer.stats}</p>
//           </div>
//         </div>
//         <button className="invite-campaign-btn">Invite to Campaign</button>
//       </div>

//       {/* SERVICES OFFERED */}
//       <div className="services-section">
//         <h2>Services Offered</h2>
//         <div className="services-cards">
//           {influencer.services.map((service, index) => (
//             <div className="service-card" key={index}>
//               <div className="service-icon">{service.icon}</div>
//               <h3>{service.title}</h3>
//               <p>{service.description}</p>
//             </div>
//           ))}
//         </div>
//       </div>

//       {/* PORTFOLIO */}
//       <div className="portfolio-section">
//         <h2>Portfolio</h2>
//         <div className="portfolio-grid">
//           {influencer.portfolio.map((imageUrl, idx) => (
//             <div className="portfolio-item" key={idx}>
//               <img src={imageUrl} alt={`Portfolio ${idx + 1}`} />
//             </div>
//           ))}
//         </div>
//       </div>

//       {/* REVIEWS */}
//       <div className="reviews-section">
//         <h2>Reviews</h2>
//         <div className="reviews-list">
//           {influencer.reviews.map((review, index) => (
//             <div className="review-card" key={index}>
//               <div className="review-header">
//                 <h4 className="review-author">{review.author}</h4>
//                 <div className="review-stars">{renderStars(review.rating)}</div>
//               </div>
//               <p className="review-text">{review.text}</p>
//             </div>
//           ))}
//         </div>
//       </div>

//       {/* FOOTER */}
//       <footer className="profile-footer">
//         <p>© 2025 InfluencerHub. All rights reserved.</p>
//         <div className="footer-links">
//           <a href="#terms">Terms</a>
//           <a href="#privacy">Privacy</a>
//           <a href="#contact">Contact</a>
//         </div>
//       </footer>
//     </div>
//   );
// }

// export default InfluencerProfilePublic;





import React from 'react';
import { FaMapMarkerAlt, FaUserCircle, FaCamera, FaVideo, FaBullhorn } from 'react-icons/fa';
import { AiFillStar } from 'react-icons/ai'; // For star ratings
import '../styles/InfluencerProfilePublic.css';

function InfluencerProfilePublic() {
  // Sample data with real image URLs (replace with your own if available)
  const influencer = {
    name: 'Sarah Anderson',
    city: 'Los Angeles, CA',
    stats: '245K followers · 180K followers · 50K subscribers',
    photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&q=80&w=200&h=200&fit=crop', // Example profile photo
    services: [
      {
        icon: <FaCamera />,
        title: 'Photo Content',
        description: 'Professional photography for products and brands',
      },
      {
        icon: <FaVideo />,
        title: 'Video Content',
        description: 'Engaging video content for social media',
      },
      {
        icon: <FaBullhorn />,
        title: 'Brand Promotion',
        description: 'Sponsored posts and brand partnerships',
      },
    ],
    portfolio: [
      // Real image URLs matching the portfolio style (black-and-white, professional)
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?ixlib=rb-4.0.3&q=80&w=400&h=400&fit=crop&sat=-100', // Group photo
      'https://images.unsplash.com/photo-1519085360753-af011efdaa89?ixlib=rb-4.0.3&q=80&w=400&h=400&fit=crop&sat=-100', // Video shoot
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?ixlib=rb-4.0.3&q=80&w=400&h=400&fit=crop&sat=-100', // Product shot
    ],
    reviews: [
      {
        author: 'John Smith',
        rating: 5,
        text: 'Amazing to work with! Very professional and delivered great results for our campaign.',
      },
      {
        author: 'Emma Wilson',
        rating: 5,
        text: 'Great engagement rates and very responsive throughout the collaboration.',
      },
    ],
  };

  // Helper to render star ratings
  const renderStars = (count) => {
    const stars = [];
    for (let i = 0; i < count; i++) {
      stars.push(<AiFillStar key={i} className="star-icon" />);
    }
    return stars;
  };

  return (
    <div className="influencer-public-profile">
      {/* PROFILE HEADER SECTION */}
      <div className="profile-hero">
        <div className="profile-left">
          {influencer.photoUrl ? (
            <img src={influencer.photoUrl} alt="Profile" className="profile-photo" />
          ) : (
            <FaUserCircle className="profile-icon" />
          )}
          <div className="profile-details">
            <h1 className="profile-name">{influencer.name}</h1>
            <p className="profile-location">
              <FaMapMarkerAlt /> {influencer.city}
            </p>
            <p className="profile-stats">{influencer.stats}</p>
          </div>
        </div>
        <button className="invite-campaign-btn">Invite to Campaign</button>
      </div>

      {/* SERVICES OFFERED */}
      <div className="services-section">
        <h2>Services Offered</h2>
        <div className="services-cards">
          {influencer.services.map((service, index) => (
            <div className="service-card" key={index}>
              <div className="service-icon">{service.icon}</div>
              <h3>{service.title}</h3>
              <p>{service.description}</p>
            </div>
          ))}
        </div>
      </div>

      {/* PORTFOLIO */}
      <div className="portfolio-section">
        <h2>Portfolio</h2>
        <div className="portfolio-grid">
          {influencer.portfolio.map((imageUrl, idx) => (
            <div className="portfolio-item" key={idx}>
              <img src={imageUrl} alt={`Portfolio ${idx + 1}`} />
            </div>
          ))}
        </div>
      </div>

      {/* REVIEWS */}
      <div className="reviews-section">
        <h2>Reviews</h2>
        <div className="reviews-list">
          {influencer.reviews.map((review, index) => (
            <div className="review-card" key={index}>
              <div className="review-header">
                <h4 className="review-author">{review.author}</h4>
                <div className="review-stars">{renderStars(review.rating)}</div>
              </div>
              <p className="review-text">{review.text}</p>
            </div>
          ))}
        </div>
      </div>

      {/* FOOTER */}
      <footer className="profile-footer">
        <p>© 2025 InfluencerHub. All rights reserved.</p>
        <div className="footer-links">
          <a href="#terms">Terms</a>
          <a href="#privacy">Privacy</a>
          <a href="#contact">Contact</a>
        </div>
      </footer>
    </div>
  );
}

export default InfluencerProfilePublic;