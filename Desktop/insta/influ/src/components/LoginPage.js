

// // src/components/LoginPage.jsx
// import React, { useState } from 'react';
// import { useNavigate } from 'react-router-dom';
// import { supabase } from '../supabase';
// import '../styles/LoginPage.css';

// function LoginPage() {
//   const navigate = useNavigate();
//   const [activeTab, setActiveTab] = useState('brand');
//   const [formData, setFormData] = useState({ email: '', password: '' });
//   const [loading, setLoading] = useState(false);
//   const [error, setError] = useState(null);

//   const handleTabClick = (tab) => {
//     setActiveTab(tab);
//     setError(null);
//   };

//   const handleInputChange = (e) => {
//     setFormData((prev) => ({ ...prev, [e.target.id]: e.target.value }));
//   };

//   const handleSubmit = async (e) => {
//     e.preventDefault();
//     setLoading(true);
//     setError(null);

//     // 1) sign in with Supabase
//     const { data: signInData, error: signInErr } = await supabase.auth.signInWithPassword({
//       email: formData.email,
//       password: formData.password,
//     });
//     if (signInErr) {
//       setError(signInErr.message);
//       setLoading(false);
//       return;
//     }

//     // 2) fetch the user’s role from your users table
//     const userId = signInData.user.id;
//     const { data: usersData, error: userErr } = await supabase
//       .from('users')
//       .select('role')
//       .eq('id', userId)
//       .single();
//     if (userErr) {
//       setError('Unable to fetch user role.');
//       setLoading(false);
//       return;
//     }

//     // 3) redirect based on role
//     if (usersData.role === 'brand') {
//       navigate('/brand-dashboard');
//     } else if (usersData.role === 'influencer') {
//       navigate('/dashboard');
//     } else {
//       // fallback
//       navigate('/');
//     }

//     setLoading(false);
//   };

//   return (
//     <div className="login-page">
//       <div className="login-card">
//         <h2 className="welcome-heading">Welcome Back</h2>
//         <p className="subheading">Sign in to your account</p>

//         {/* Tabs */}
//         <div className="tab-container">
//           <button
//             className={`tab-btn ${activeTab === 'brand' ? 'active' : ''}`}
//             onClick={() => handleTabClick('brand')}
//           >
//             Brand Login
//           </button>
//           <button
//             className={`tab-btn ${activeTab === 'influencer' ? 'active' : ''}`}
//             onClick={() => handleTabClick('influencer')}
//           >
//             Influencer Login
//           </button>
//         </div>

//         {error && <p className="error-message">{error}</p>}

//         {/* Form */}
//         <form className="login-form" onSubmit={handleSubmit}>
//           <label htmlFor="email" className="form-label">
//             Email address
//           </label>
//           <input
//             type="email"
//             id="email"
//             className="form-input"
//             placeholder="Enter your email"
//             value={formData.email}
//             onChange={handleInputChange}
//             required
//           />

//           <label htmlFor="password" className="form-label">
//             Password
//           </label>
//           <input
//             type="password"
//             id="password"
//             className="form-input"
//             placeholder="Enter your password"
//             value={formData.password}
//             onChange={handleInputChange}
//             required
//           />

//           <div className="forgot-password">
//             <a href="#forgot">Forgot password?</a>
//           </div>

//           <button type="submit" className="login-btn" disabled={loading}>
//             {loading ? 'Logging in…' : 'Login'}
//           </button>
//         </form>

//         <p className="signup-text">
//           Don’t have an account?{' '}
//           {activeTab === 'brand' ? (
//             <a href="/signup-brand">Sign up as Brand</a>
//           ) : (
//             <a href="/signup-influencer">Sign up as Influencer</a>
//           )}
//         </p>
//       </div>
//     </div>
//   );
// }

// export default LoginPage;



import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../supabase';
import '../styles/LoginPage.css';

function LoginPage() {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('brand');
  const [formData, setFormData] = useState({ email: '', password: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleTabClick = (tab) => {
    setActiveTab(tab);
    setError(null);
  };

  const handleInputChange = (e) => {
    setFormData((prev) => ({ ...prev, [e.target.id]: e.target.value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    // 1) sign in with Supabase
    const { data: signInData, error: signInErr } = await supabase.auth.signInWithPassword({
      email: formData.email,
      password: formData.password,
    });
    if (signInErr) {
      setError(signInErr.message);
      setLoading(false);
      return;
    }

    // 2) fetch the user’s role from your users table
    const userId = signInData.user.id;
    const { data: usersData, error: userErr } = await supabase
      .from('users')
      .select('role')
      .eq('id', userId)
      .single();
    if (userErr) {
      setError('Unable to fetch user role.');
      setLoading(false);
      return;
    }

    // 3) redirect based on role
    if (usersData.role === 'brand') {
      navigate('/brand-dashboard');
    } else if (usersData.role === 'influencer') {
      navigate('/dashboard');
    } else {
      // fallback
      navigate('/');
    }

    setLoading(false);
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <h2 className="welcome-heading">Welcome Back</h2>
        <p className="subheading">Sign in to your account</p>

        {/* Tabs */}
        <div className="tab-container">
          <button
            className={`tab-btn ${activeTab === 'brand' ? 'active' : ''}`}
            onClick={() => handleTabClick('brand')}
          >
            Brand Login
          </button>
          <button
            className={`tab-btn ${activeTab === 'influencer' ? 'active' : ''}`}
            onClick={() => handleTabClick('influencer')}
          >
            Influencer Login
          </button>
        </div>

        {error && <p className="error-message">{error}</p>}

        {/* Form */}
        <form className="login-form" onSubmit={handleSubmit}>
          <label htmlFor="email" className="form-label">
            Email address
          </label>
          <input
            type="email"
            id="email"
            className="form-input"
            placeholder="Enter your email"
            value={formData.email}
            onChange={handleInputChange}
            required
          />

          <label htmlFor="password" className="form-label">
            Password
          </label>
          <input
            type="password"
            id="password"
            className="form-input"
            placeholder="Enter your password"
            value={formData.password}
            onChange={handleInputChange}
            required
          />

          <div className="forgot-password">
            <a href="#forgot">Forgot password?</a>
          </div>

          <button type="submit" className="login-btn" disabled={loading}>
            {loading ? 'Logging in…' : 'Login'}
          </button>
        </form>

        <p className="signup-text">
          Don’t have an account?{' '}
          {activeTab === 'brand' ? (
            <a href="/signup-brand">Sign up as Brand</a>
          ) : (
            <a href="/signup-influencer">Sign up as Influencer</a>
          )}
        </p>
      </div>
    </div>
  );
}

export default LoginPage;