



// // src/components/CreateCampaign.jsx
// import React, { useState } from 'react';
// import { useNavigate } from 'react-router-dom';
// import { supabase } from '../supabase';
// import {
//   FaTimes,
//   FaInstagram,
//   FaYoutube,
//   FaFilm,
//   FaMapMarkerAlt,
//   FaBookOpen,
//   FaRegImage,
//   FaAd,
//   FaCalendarAlt
// } from 'react-icons/fa';
// import { SiTiktok } from 'react-icons/si';
// import '../styles/CreateCampaign.css';

// export default function CreateCampaign() {
//   const navigate = useNavigate();
//   const [title, setTitle]               = useState('');
//   const [description, setDescription]   = useState('');
//   const [budgetMin, setBudgetMin]       = useState('');
//   const [budgetMax, setBudgetMax]       = useState('');
//   const [platforms, setPlatforms]       = useState([]);
//   const [location, setLocation]         = useState('');
//   const [deliverables, setDeliverables] = useState([]);
//   const [startDate, setStartDate]       = useState('');
//   const [endDate, setEndDate]           = useState('');
//   const [loading, setLoading]           = useState(false);
//   const [error, setError]               = useState(null);

//   const toggle = (arr, val) =>
//     arr.includes(val) ? arr.filter(v => v !== val) : [...arr, val];

//   const handleSubmit = async (e) => {
//     e.preventDefault();
//     setLoading(true);
//     setError(null);
//     try {
//       const { data: { user }, error: authErr } = await supabase.auth.getUser();
//       if (authErr || !user) throw new Error('Please log in first.');

//       const { error: dbErr } = await supabase.from('campaigns').insert([{
//         brand_id     : user.id,
//         name         : title,
//         description,
//         budget       : parseFloat(budgetMax) || 0,
//         budget_min   : parseFloat(budgetMin) || 0,
//         budget_max   : parseFloat(budgetMax) || 0,
//         platforms,
//         location,
//         deliverables,
//         start_date   : startDate || null,
//         end_date     : endDate   || null,
//         status       : 'Pending'
//       }]);
//       if (dbErr) throw dbErr;
//       navigate('/brand-dashboard');
//     } catch (err) {
//       setError(err.message);
//     } finally {
//       setLoading(false);
//     }
//   };

//   return (
//     <div className="create-campaign-container">
//       <div className="create-campaign-header">
//         <h2>Create New Campaign</h2>
//         <button
//           type="button"
//           className="close-modal-btn"
//           onClick={() => navigate(-1)}
//           disabled={loading}
//         >
//           <FaTimes />
//         </button>
//       </div>
//       {error && <p className="error-message">{error}</p>}
//       <form className="create-campaign-form" onSubmit={handleSubmit}>
//         <div className="form-group">
//           <label htmlFor="title" className="form-label">Campaign Title</label>
//           <input
//             id="title"
//             className="form-input"
//             placeholder="Enter campaign title"
//             value={title}
//             onChange={e => setTitle(e.target.value)}
//             required
//           />
//         </div>
//         <div className="form-group">
//           <label htmlFor="description" className="form-label">Description</label>
//           <textarea
//             id="description"
//             className="form-textarea"
//             rows="3"
//             placeholder="Describe your campaign"
//             value={description}
//             onChange={e => setDescription(e.target.value)}
//           />
//         </div>
//         <div className="form-group">
//           <label className="form-label">Budget Range</label>
//           <div className="budget-range">
//             <input
//               type="number"
//               min="0"
//               placeholder="Min"
//               className="budget-input"
//               value={budgetMin}
//               onChange={e => setBudgetMin(e.target.value)}
//             />
//             <span className="range-dash">–</span>
//             <input
//               type="number"
//               min="0"
//               placeholder="Max"
//               className="budget-input"
//               value={budgetMax}
//               onChange={e => setBudgetMax(e.target.value)}
//             />
//           </div>
//         </div>
//         <div className="form-group">
//           <label className="form-label">Select Platforms</label>
//           <div className="checkbox-group">
//             {[
//               ['Instagram', FaInstagram],
//               ['YouTube',    FaYoutube],
//               ['TikTok',     SiTiktok],
//               ['Reels',      FaFilm]
//             ].map(([name, Icon]) => (
//               <label key={name} className="checkbox-label">
//                 <Icon />
//                 <input
//                   type="checkbox"
//                   checked={platforms.includes(name)}
//                   onChange={() => setPlatforms(toggle(platforms, name))}
//                 />
//                 {name}
//               </label>
//             ))}
//           </div>
//         </div>
//         <div className="form-group">
//           <label htmlFor="location" className="form-label">
//             <FaMapMarkerAlt /> Location
//           </label>
//           <input
//             id="location"
//             className="form-input"
//             placeholder="Enter location"
//             value={location}
//             onChange={e => setLocation(e.target.value)}
//           />
//         </div>
//         <div className="form-group">
//           <label className="form-label">Content Deliverables</label>
//           <div className="checkbox-group">
//             {[
//               ['Stories',        FaBookOpen],
//               ['Feed',           FaRegImage],
//               ['Reel',           FaFilm],
//               ['Sponsored Post', FaAd]
//             ].map(([name, Icon]) => (
//               <label key={name} className="checkbox-label">
//                 <Icon />
//                 <input
//                   type="checkbox"
//                   checked={deliverables.includes(name)}
//                   onChange={() => setDeliverables(toggle(deliverables, name))}
//                 />
//                 {name}
//               </label>
//             ))}
//           </div>
//         </div>
//         <div className="form-group">
//           <label className="form-label"><FaCalendarAlt /> Campaign Duration</label>
//           <div className="date-range">
//             <div>
//               <label htmlFor="startDate" className="date-label">Start Date</label>
//               <input
//                 id="startDate"
//                 type="date"
//                 className="date-input"
//                 value={startDate}
//                 onChange={e => setStartDate(e.target.value)}
//               />
//             </div>
//             <div>
//               <label htmlFor="endDate" className="date-label">End Date</label>
//               <input
//                 id="endDate"
//                 type="date"
//                 className="date-input"
//                 value={endDate}
//                 onChange={e => setEndDate(e.target.value)}
//               />
//             </div>
//           </div>
//         </div>
//         <div className="form-group button-row">
//           <button
//             type="submit"
//             className="create-campaign-btn"
//             disabled={loading}
//           >
//             {loading ? 'Creating…' : 'Create Campaign'}
//           </button>
//         </div>
//       </form>
//     </div>
//   );
// }



import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../supabase';
import {
  FaTimes,
  FaInstagram,
  FaYoutube,
  FaFilm,
  FaMapMarkerAlt,
  FaBookOpen,
  FaRegImage,
  FaAd,
  FaCalendarAlt
} from 'react-icons/fa';
import { SiTiktok } from 'react-icons/si';
import '../styles/CreateCampaign.css';

export default function CreateCampaign() {
  const navigate = useNavigate();
  const [title, setTitle]               = useState('');
  const [description, setDescription]   = useState('');
  const [budgetMin, setBudgetMin]       = useState('');
  const [budgetMax, setBudgetMax]       = useState('');
  const [platforms, setPlatforms]       = useState([]);
  const [location, setLocation]         = useState('');
  const [deliverables, setDeliverables] = useState([]);
  const [startDate, setStartDate]       = useState('');
  const [endDate, setEndDate]           = useState('');
  const [loading, setLoading]           = useState(false);
  const [error, setError]               = useState(null);

  const toggle = (arr, val) =>
    arr.includes(val) ? arr.filter(v => v !== val) : [...arr, val];

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const { data: { user }, error: authErr } = await supabase.auth.getUser();
      if (authErr || !user) throw new Error('Please log in first.');

      const { error: dbErr } = await supabase.from('campaigns').insert([{
        brand_id     : user.id,
        name         : title,
        description,
        budget       : parseFloat(budgetMax) || 0,
        budget_min   : parseFloat(budgetMin) || 0,
        budget_max   : parseFloat(budgetMax) || 0,
        platforms,
        location,
        deliverables,
        start_date   : startDate || null,
        end_date     : endDate   || null,
        status       : 'Pending'
      }]);
      if (dbErr) throw dbErr;
      navigate('/brand-dashboard');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="create-campaign-container">
      <div className="create-campaign-header">
        <h2>Create New Campaign</h2>
        <button
          type="button"
          className="close-modal-btn"
          onClick={() => navigate(-1)}
          disabled={loading}
        >
          <FaTimes />
        </button>
      </div>
      {error && <p className="error-message">{error}</p>}
      <form className="create-campaign-form" onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="title" className="form-label">Campaign Title</label>
          <input
            id="title"
            className="form-input"
            placeholder="Enter campaign title"
            value={title}
            onChange={e => setTitle(e.target.value)}
            required
          />
        </div>
        <div className="form-group">
          <label htmlFor="description" className="form-label">Description</label>
          <textarea
            id="description"
            className="form-textarea"
            rows="3"
            placeholder="Describe your campaign"
            value={description}
            onChange={e => setDescription(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label className="form-label">Budget Range</label>
          <div className="budget-range">
            <input
              type="number"
              min="0"
              placeholder="Min"
              className="budget-input"
              value={budgetMin}
              onChange={e => setBudgetMin(e.target.value)}
            />
            <span className="range-dash">–</span>
            <input
              type="number"
              min="0"
              placeholder="Max"
              className="budget-input"
              value={budgetMax}
              onChange={e => setBudgetMax(e.target.value)}
            />
          </div>
        </div>
        <div className="form-group">
          <label className="form-label">Select Platforms</label>
          <div className="checkbox-group">
            {[
              ['Instagram', FaInstagram],
              ['YouTube',    FaYoutube],
              ['TikTok',     SiTiktok],
              ['Reels',      FaFilm]
            ].map(([name, Icon]) => (
              <label key={name} className="checkbox-label">
                <Icon />
                <input
                  type="checkbox"
                  checked={platforms.includes(name)}
                  onChange={() => setPlatforms(toggle(platforms, name))}
                />
                {name}
              </label>
            ))}
          </div>
        </div>
        <div className="form-group">
          <label htmlFor="location" className="form-label">
            <FaMapMarkerAlt /> Location
          </label>
          <input
            id="location"
            className="form-input"
            placeholder="Enter location"
            value={location}
            onChange={e => setLocation(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label className="form-label">Content Deliverables</label>
          <div className="checkbox-group">
            {[
              ['Stories',        FaBookOpen],
              ['Feed',           FaRegImage],
              ['Reel',           FaFilm],
              ['Sponsored Post', FaAd]
            ].map(([name, Icon]) => (
              <label key={name} className="checkbox-label">
                <Icon />
                <input
                  type="checkbox"
                  checked={deliverables.includes(name)}
                  onChange={() => setDeliverables(toggle(deliverables, name))}
                />
                {name}
              </label>
            ))}
          </div>
        </div>
        <div className="form-group">
          <label className="form-label"><FaCalendarAlt /> Campaign Duration</label>
          <div className="date-range">
            <div>
              <label htmlFor="startDate" className="date-label">Start Date</label>
              <input
                id="startDate"
                type="date"
                className="date-input"
                value={startDate}
                onChange={e => setStartDate(e.target.value)}
              />
            </div>
            <div>
              <label htmlFor="endDate" className="date-label">End Date</label>
              <input
                id="endDate"
                type="date"
                className="date-input"
                value={endDate}
                onChange={e => setEndDate(e.target.value)}
              />
            </div>
          </div>
        </div>
        <div className="form-group button-row">
          <button
            type="submit"
            className="create-campaign-btn"
            disabled={loading}
          >
            {loading ? 'Creating…' : 'Create Campaign'}
          </button>
        </div>
      </form>
    </div>
  );
}