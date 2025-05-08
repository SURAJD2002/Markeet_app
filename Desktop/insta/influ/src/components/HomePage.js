// import React from 'react';
// import { Link } from 'react-router-dom';
// import '../styles/HomePage.css';

// function HomePage() {
//   return (
//     <div className="home-page">
//       <header className="hero-section">
//         <div className="hero-content">
//           <h1>Connect Local Brands with Perfect Influencers</h1>
//           <p>
//             Build authentic partnerships and grow your business with our platform
//             that connects local brands with influential creators in your area.
//           </p>
//           <div className="hero-buttons">
//             <button className="brand-btn">I'm a Brand</button>
//             <button className="influencer-btn">I'm an Influencer</button>
//           </div>
//         </div>
//       </header>

//       <section className="features-section">
//         <div className="feature-card">
//           <span className="feature-icon">🔍</span>
//           <h3>Find Perfect Matches</h3>
//           <p>Connect with brands or influencers that align with your values and goals.</p>
//         </div>
//         <div className="feature-card">
//           <span className="feature-icon">🤝</span>
//           <h3>Easy Collaboration</h3>
//           <p>Streamlined process for campaign creation, approval, and execution.</p>
//         </div>
//         <div className="feature-card">
//           <span className="feature-icon">📊</span>
//           <h3>Track Performance</h3>
//           <p>Detailed analytics and insights to measure campaign success.</p>
//         </div>
//       </section>

//       <section className="how-it-works-section">
//         <h2>How It Works</h2>
//         <div className="how-it-works-cards">
//           <div className="how-it-works-card">
//             <span className="how-it-works-icon">👤</span>
//             <h3>Create Account</h3>
//             <p>Sign up as a brand or influencer and complete your profile.</p>
//           </div>
//           <div className="how-it-works-card">
//             <span className="how-it-works-icon">💬</span>
//             <h3>Collaborate</h3>
//             <p>Connect, discuss, and create amazing campaigns together.</p>
//           </div>
//           <div className="how-it-works-card">
//             <span className="how-it-works-icon">🚀</span>
//             <h3>Grow</h3>
//             <p>Track results and scale your success together.</p>
//           </div>
//         </div>
//       </section>

//       <section className="trusted-brands-section">
//         <h2>Trusted by Leading Brands</h2>
//         <div className="brands-logos">
//           <div className="brand-logo"></div>
//           <div className="brand-logo"></div>
//           <div className="brand-logo"></div>
//           <div className="brand-logo"></div>
//         </div>
//       </section>

//       <footer className="footer-section">
//         <div className="footer-column">
//           <h3>InfluenceLocal</h3>
//           <p>Connecting local brands with influential creators.</p>
//         </div>
//         <div className="footer-column">
//           <h3>Quick Links</h3>
//           <Link to="/about">About Us</Link>
//           <Link to="/how-it-works">How It Works</Link>
//           <Link to="/for-brands">For Brands</Link>
//           <Link to="/for-influencers">For Influencers</Link>
//         </div>
//         <div className="footer-column">
//           <h3>Legal</h3>
//           <Link to="/privacy-policy">Privacy Policy</Link>
//           <Link to="/terms-of-service">Terms of Service</Link>
//         </div>
//         <div className="footer-column">
//           <h3>Follow Us</h3>
//           <span className="social-icon">📸</span>
//           <span className="social-icon">🐦</span>
//           <span className="social-icon">linkedin</span>
//         </div>
//         <p className="footer-copyright">
//           © 2025 InfluenceLocal. All rights reserved.
//         </p>
//       </footer>
//     </div>
//   );
// }

// export default HomePage;




import React, { useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../supabase'; // Adjust path based on your setup
import '../styles/HomePage.css';

function HomePage() {
  const navigate = useNavigate();

  // Check authentication status on mount
  useEffect(() => {
    const checkUser = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (user) {
          // Fetch user role from users table
          const { data, error } = await supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .single();
          
          if (error) throw error;

          // Redirect based on role
          if (data.role === 'brand') {
            navigate('/brand-dashboard');
          } else if (data.role === 'influencer') {
            navigate('/dashboard');
          }
        }
      } catch (error) {
        console.error('Error checking user:', error.message);
      }
    };

    checkUser();
  }, [navigate]);

  // Handle button clicks for unauthenticated users
  const handleBrandClick = () => {
    navigate('/signup-brand');
  };

  const handleInfluencerClick = () => {
    navigate('/signup-influencer');
  };

  return (
    <div className="home-page">
      <header className="hero-section">
        <div className="hero-content">
          <h1>Connect Local Brands with Perfect Influencers</h1>
          <p>
            Build authentic partnerships and grow your business with our platform
            that connects local brands with influential creators in your area.
          </p>
          <div className="hero-buttons">
            <button className="brand-btn" onClick={handleBrandClick}>
              I'm a Brand
            </button>
            <button className="influencer-btn" onClick={handleInfluencerClick}>
              I'm an Influencer
            </button>
          </div>
        </div>
      </header>

      <section className="features-section">
        <div className="feature-card">
          <span className="feature-icon">🔍</span>
          <h3>Find Perfect Matches</h3>
          <p>Connect with brands or influencers that align with your values and goals.</p>
        </div>
        <div className="feature-card">
          <span className="feature-icon">🤝</span>
          <h3>Easy Collaboration</h3>
          <p>Streamlined process for campaign creation, approval, and execution.</p>
        </div>
        <div className="feature-card">
          <span className="feature-icon">📊</span>
          <h3>Track Performance</h3>
          <p>Detailed analytics and insights to measure campaign success.</p>
        </div>
      </section>

      <section className="how-it-works-section">
        <h2>How It Works</h2>
        <div className="how-it-works-cards">
          <div className="how-it-works-card">
            <span className="how-it-works-icon">👤</span>
            <h3>Create Account</h3>
            <p>Sign up as a brand or influencer and complete your profile.</p>
          </div>
          <div className="how-it-works-card">
            <span className="how-it-works-icon">💬</span>
            <h3>Collaborate</h3>
            <p>Connect, discuss, and create amazing campaigns together.</p>
          </div>
          <div className="how-it-works-card">
            <span className="how-it-works-icon">🚀</span>
            <h3>Grow</h3>
            <p>Track results and scale your success together.</p>
          </div>
        </div>
      </section>

      <section className="trusted-brands-section">
        <h2>Trusted by Leading Brands</h2>
        <div className="brands-logos">
          <div className="brand-logo"></div>
          <div className="brand-logo"></div>
          <div className="brand-logo"></div>
          <div className="brand-logo"></div>
        </div>
      </section>

      <footer className="footer-section">
        <div className="footer-column">
          <h3>InfluenceLocal</h3>
          <p>Connecting local brands with influential creators.</p>
        </div>
        <div className="footer-column">
          <h3>Quick Links</h3>
          <Link to="/about">About Us</Link>
          <Link to="/how-it-works">How It Works</Link>
          <Link to="/for-brands">For Brands</Link>
          <Link to="/for-influencers">For Influencers</Link>
        </div>
        <div className="footer-column">
          <h3>Legal</h3>
          <Link to="/privacy-policy">Privacy Policy</Link>
          <Link to="/terms-of-service">Terms of Service</Link>
        </div>
        <div className="footer-column">
          <h3>Follow Us</h3>
          <span className="social-icon">📸</span>
          <span className="social-icon">🐦</span>
          <span className="social-icon">linkedin</span>
        </div>
        <p className="footer-copyright">
          © 2025 InfluenceLocal. All rights reserved.
        </p>
      </footer>
    </div>
  );
}

export default HomePage;