// import React from 'react';
// import '../styles/Navbar.css';

// function Navbar() {
//   return (
//     <nav className="navbar">
//       <div className="nav-left">
//         <span className="nav-logo">Influence.local</span>
//       </div>

//       <div className="nav-right">
//         <a href="#howitworks">How It Works</a>
//         <a href="#forbrands">For Brands</a>
//         <a href="#forinfluencers">For Influencers</a>
//         <a href="#login">Login</a>
//         <button className="signup-btn">Sign Up</button>
//       </div>
//     </nav>
//   );
// }

// export default Navbar;



// import React, { useEffect, useState } from 'react';
// import { Link, useNavigate } from 'react-router-dom';
// import { supabase } from '../supabase'; // Adjust path based on your setup
// import '../styles/Navbar.css';

// function Navbar() {
//   const navigate = useNavigate();
//   const [user, setUser] = useState(null);
//   const [userRole, setUserRole] = useState(null);

//   // Check authentication status on mount
//   useEffect(() => {
//     const checkUser = async () => {
//       try {
//         const { data: { user } } = await supabase.auth.getUser();
//         if (user) {
//           setUser(user);
//           // Fetch user role
//           const { data, error } = await supabase
//             .from('users')
//             .select('role')
//             .eq('id', user.id)
//             .single();
//           if (error) throw error;
//           setUserRole(data.role);
//         }
//       } catch (error) {
//         console.error('Error checking user:', error.message);
//       }
//     };

//     checkUser();

//     // Listen for auth changes
//     const { data: authListener } = supabase.auth.onAuthStateChange((event, session) => {
//       setUser(session?.user ?? null);
//       if (session?.user) {
//         checkUser();
//       } else {
//         setUserRole(null);
//       }
//     });

//     return () => authListener.subscription.unsubscribe();
//   }, []);

//   // Handle sign-up button click
//   const handleSignUp = () => {
//     navigate('/signup-brand'); // Default to brand sign-up; could be a wrapper page
//   };

//   // Handle logout
//   const handleLogout = async () => {
//     try {
//       await supabase.auth.signOut();
//       navigate('/');
//     } catch (error) {
//       console.error('Logout error:', error.message);
//     }
//   };

//   return (
//     <nav className="navbar">
//       <div className="nav-left">
//         <Link to="/" className="nav-logo">Influence.local</Link>
//       </div>

//       <div className="nav-right">
//         {user ? (
//           <>
//             <Link to={userRole === 'brand' ? '/brand-dashboard' : '/dashboard'}>Dashboard</Link>
//             <button className="logout-btn" onClick={handleLogout}>Logout</button>
//           </>
//         ) : (
//           <>
//             <Link to="/how-it-works">How It Works</Link>
//             <Link to="/for-brands">For Brands</Link>
//             <Link to="/for-influencers">For Influencers</Link>
//             <Link to="/login">Login</Link>
//             <button className="signup-btn" onClick={handleSignUp}>Sign Up</button>
//           </>
//         )}
//       </div>
//     </nav>
//   );
// }

// export default Navbar;



import React from 'react';
import { NavLink } from 'react-router-dom';
import { FaTachometerAlt, FaBullhorn, FaChartLine, FaWallet, FaCog, FaHome, FaInfoCircle, FaSignInAlt, FaDollarSign } from 'react-icons/fa';
import '../styles/Navbar.css';

const navItems = [
  { id: 'home', label: 'Home', icon: <FaHome />, path: '/' },
  { id: 'dashboard', label: 'Dashboard', icon: <FaTachometerAlt />, path: '/dashboard' },
  { id: 'campaigns', label: 'Campaigns', icon: <FaBullhorn />, path: '/CampaignListingPage' },
  { id: 'analytics', label: 'Analytics', icon: <FaChartLine />, path: '/analytics' },
  { id: 'earnings', label: 'Earnings', icon: <FaWallet />, path: '/earnings' },
  { id: 'settings', label: 'Settings', icon: <FaCog />, path: '/settings' },
  { id: 'about', label: 'About', icon: <FaInfoCircle />, path: '/about' },
  { id: 'login', label: 'Login', icon: <FaSignInAlt />, path: '/login' },
  { id: 'pricing', label: 'Pricing', icon: <FaDollarSign />, path: '/pricing' },
];

const Navbar = () => {
  return (
    <aside className="navbar">
      <h1 className="navbar__logo">InfluenceHub</h1>
      <nav className="navbar__nav">
        {navItems.map((item) => (
          <NavLink
            key={item.id}
            to={item.path}
            className={({ isActive }) =>
              `navbar__item${isActive ? ' navbar__item--active' : ''}`
            }
          >
            <span className="navbar__icon">{item.icon}</span>
            {item.label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
};

export default Navbar;