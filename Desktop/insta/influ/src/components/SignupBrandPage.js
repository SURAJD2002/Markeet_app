// import React, { useState } from 'react';
// import { Link, useNavigate } from 'react-router-dom';
// import { supabase } from '../supabase';
// import '../styles/Signup.css';

// function SignupBrandPage() {
//   const navigate = useNavigate();
//   const [loading, setLoading] = useState(false);
//   const [error, setError] = useState(null);
//   const [formData, setFormData] = useState({
//     brandName: '',
//     businessEmail: '',
//     brandPassword: '',
//     brandLocation: '',
//     brandIndustry: '',
//   });

//   const handleInputChange = (e) => {
//     const { name, value } = e.target;
//     setFormData((prev) => ({ ...prev, [name]: value }));
//   };

//   const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

//   const signUpWithRetry = async (email, password, maxRetries = 3, baseDelay = 2000) => {
//     let attempt = 0;
//     while (attempt < maxRetries) {
//       try {
//         await delay(baseDelay * (2 ** attempt));
//         const response = await supabase.auth.signUp({ email, password });
//         if (response.error) {
//           throw response.error;
//         }
//         return response;
//       } catch (err) {
//         console.error('Sign-up error:', {
//           status: err.status,
//           message: err.message,
//           details: err,
//           attempt: attempt + 1,
//         });
//         if (err.status === 429 || err.status === 500) {
//           attempt++;
//           if (attempt === maxRetries) {
//             throw new Error(
//               err.status === 429
//                 ? 'Too many requests. Please try again later.'
//                 : 'Authentication server error. Please try again or contact support.'
//             );
//           }
//         } else {
//           throw err;
//         }
//       }
//     }
//   };

//   const handleBrandSignup = async (e) => {
//     e.preventDefault();
//     setLoading(true);
//     setError(null);

//     try {
//       const { data: { user, session }, error: authError } = await signUpWithRetry(
//         formData.businessEmail,
//         formData.brandPassword
//       );
//       if (authError) throw authError;
//       if (!user) throw new Error('User creation failed.');

//       // Log session state
//       console.log('Session after signUp:', { session, userId: user.id });

//       // Force session refresh
//       if (!session) {
//         const { data: sessionData, error: sessionError } = await supabase.auth.getSession();
//         if (sessionError) {
//           console.error('Session refresh error:', sessionError);
//           throw sessionError;
//         }
//         console.log('Refreshed session:', sessionData.session);
//       }

//       // Verify current user
//       const { data: currentUser, error: userError } = await supabase.auth.getUser();
//       if (userError || !currentUser.user) {
//         console.error('Current user error:', userError);
//         throw new Error('Failed to verify authenticated user.');
//       }
//       console.log('Current user:', currentUser.user.id);

//       // Insert into brands table
//       const { error: brandError } = await supabase
//         .from('brands')
//         .insert([
//           {
//             user_id: user.id,
//             brand_name: formData.brandName,
//             location: formData.brandLocation,
//             industry: formData.brandIndustry,
//           },
//         ]);
//       if (brandError) {
//         console.error('Brands insert error:', {
//           message: brandError.message,
//           details: brandError.details,
//           hint: brandError.hint,
//           code: brandError.code,
//         });
//         throw brandError;
//       }

//       navigate('/brand-dashboard');
//     } catch (error) {
//       setError(error.message || 'Error creating account. Please try again.');
//     } finally {
//       setLoading(false);
//     }
//   };

//   return (
//     <div className="signup-card">
//       <div className="signup-icon" aria-hidden="true">🏢</div>
//       <h2 className="signup-title">Sign up as a Brand</h2>
//       <p className="signup-subtitle">Create an account to find influencers</p>
//       {error && <p className="error-message">{error}</p>}
//       <form className="signup-form" onSubmit={handleBrandSignup}>
//         <label htmlFor="brandName">Brand Name</label>
//         <input
//           type="text"
//           id="brandName"
//           name="brandName"
//           value={formData.brandName}
//           onChange={handleInputChange}
//           placeholder="Your brand name"
//           required
//         />
//         <label htmlFor="businessEmail">Business Email</label>
//         <input
//           type="email"
//           id="businessEmail"
//           name="businessEmail"
//           value={formData.businessEmail}
//           onChange={handleInputChange}
//           placeholder="you@company.com"
//           required
//         />
//         <label htmlFor="brandPassword">Password</label>
//         <input
//           type="password"
//           id="brandPassword"
//           name="brandPassword"
//           value={formData.brandPassword}
//           onChange={handleInputChange}
//           placeholder="********"
//           required
//         />
//         <label htmlFor="brandLocation">Location</label>
//         <select
//           id="brandLocation"
//           name="brandLocation"
//           value={formData.brandLocation}
//           onChange={handleInputChange}
//           required
//         >
//           <option value="" disabled>Select location</option>
//           <option value="New York">New York</option>
//           <option value="Los Angeles">Los Angeles</option>
//           <option value="Chicago">Chicago</option>
//           <option value="Houston">Houston</option>
//           <option value="Other">Other</option>
//         </select>
//         <label htmlFor="brandIndustry">Industry</label>
//         <select
//           id="brandIndustry"
//           name="brandIndustry"
//           value={formData.brandIndustry}
//           onChange={handleInputChange}
//           required
//         >
//           <option value="" disabled>Select industry</option>
//           <option value="Fashion">Fashion</option>
//           <option value="Beauty">Beauty</option>
//           <option value="Tech">Tech</option>
//           <option value="Food & Beverage">Food & Beverage</option>
//           <option value="Other">Other</option>
//         </select>
//         <button type="submit" className="signup-button" disabled={loading}>
//           {loading ? 'Signing up...' : 'Sign up as Brand'}
//         </button>
//       </form>
//       <p className="login-text">
//         Already have an account? <Link to="/login">Log in</Link>
//       </p>
//     </div>
//   );
// }

// export default SignupBrandPage;




import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../supabase';
import '../styles/Signup.css';

function SignupBrandPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [formData, setFormData] = useState({
    brandName: '',
    businessEmail: '',
    brandPassword: '',
    brandLocation: '',
    brandIndustry: '',
  });

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  const signUpWithRetry = async (email, password, maxRetries = 3, baseDelay = 2000) => {
    let attempt = 0;
    while (attempt < maxRetries) {
      try {
        await delay(baseDelay * (2 ** attempt));
        const response = await supabase.auth.signUp({ email, password });
        if (response.error) {
          throw response.error;
        }
        return response;
      } catch (err) {
        console.error('Sign-up error:', {
          status: err.status,
          message: err.message,
          details: err,
          attempt: attempt + 1,
        });
        if (err.status === 429 || err.status === 500) {
          attempt++;
          if (attempt === maxRetries) {
            throw new Error(
              err.status === 429
                ? 'Too many requests. Please try again later.'
                : 'Authentication server error. Please try again or contact support.'
            );
          }
        } else {
          throw err;
        }
      }
    }
  };

  const handleBrandSignup = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const { data: { user, session }, error: authError } = await signUpWithRetry(
        formData.businessEmail,
        formData.brandPassword
      );
      if (authError) throw authError;
      if (!user) throw new Error('User creation failed.');

      // Log session state
      console.log('Session after signUp:', { session, userId: user.id });

      // Force session refresh
      if (!session) {
        const { data: sessionData, error: sessionError } = await supabase.auth.getSession();
        if (sessionError) {
          console.error('Session refresh error:', sessionError);
          throw sessionError;
        }
        console.log('Refreshed session:', sessionData.session);
      }

      // Verify current user
      const { data: currentUser, error: userError } = await supabase.auth.getUser();
      if (userError || !currentUser.user) {
        console.error('Current user error:', userError);
        throw new Error('Failed to verify authenticated user.');
      }
      console.log('Current user:', currentUser.user.id);

      // Insert into brands table
      const { error: brandError } = await supabase
        .from('brands')
        .insert([
          {
            user_id: user.id,
            brand_name: formData.brandName,
            location: formData.brandLocation,
            industry: formData.brandIndustry,
          },
        ]);
      if (brandError) {
        console.error('Brands insert error:', {
          message: brandError.message,
          details: brandError.details,
          hint: brandError.hint,
          code: brandError.code,
        });
        throw brandError;
      }

      navigate('/brand-dashboard');
    } catch (error) {
      setError(error.message || 'Error creating account. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="signup-page">
      <div className="signup-card">
        <div className="signup-icon" aria-hidden="true">🏢</div>
        <h2 className="signup-title">Sign up as a Brand</h2>
        <p className="signup-subtitle">Create an account to find influencers</p>

        {error && <p className="error-message">{error}</p>}

        <form className="signup-form" onSubmit={handleBrandSignup}>
          <label htmlFor="brandName" className="form-label">Brand Name</label>
          <input
            type="text"
            id="brandName"
            name="brandName"
            value={formData.brandName}
            onChange={handleInputChange}
            placeholder="Your brand name"
            required
            className="form-input"
          />

          <label htmlFor="businessEmail" className="form-label">Business Email</label>
          <input
            type="email"
            id="businessEmail"
            name="businessEmail"
            value={formData.businessEmail}
            onChange={handleInputChange}
            placeholder="you@company.com"
            required
            className="form-input"
          />

          <label htmlFor="brandPassword" className="form-label">Password</label>
          <input
            type="password"
            id="brandPassword"
            name="brandPassword"
            value={formData.brandPassword}
            onChange={handleInputChange}
            placeholder="********"
            required
            className="form-input"
          />

          <label htmlFor="brandLocation" className="form-label">Location</label>
          <select
            id="brandLocation"
            name="brandLocation"
            value={formData.brandLocation}
            onChange={handleInputChange}
            required
            className="form-input"
          >
            <option value="" disabled>Select location</option>
            <option value="New York">New York</option>
            <option value="Los Angeles">Los Angeles</option>
            <option value="Chicago">Chicago</option>
            <option value="Houston">Houston</option>
            <option value="Other">Other</option>
          </select>

          <label htmlFor="brandIndustry" className="form-label">Industry</label>
          <select
            id="brandIndustry"
            name="brandIndustry"
            value={formData.brandIndustry}
            onChange={handleInputChange}
            required
            className="form-input"
          >
            <option value="" disabled>Select industry</option>
            <option value="Fashion">Fashion</option>
            <option value="Beauty">Beauty</option>
            <option value="Tech">Tech</option>
            <option value="Food & Beverage">Food & Beverage</option>
            <option value="Other">Other</option>
          </select>

          <button type="submit" className="signup-button" disabled={loading}>
            {loading ? 'Signing up...' : 'Sign up as Brand'}
          </button>
        </form>

        <p className="login-text">
          Already have an account? <Link to="/login">Log in</Link>
        </p>
      </div>
    </div>
  );
}

export default SignupBrandPage;