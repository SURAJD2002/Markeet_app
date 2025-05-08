// import React from 'react';
// import "../styles/CampaignPage.css";

// function CampaignPage() {
//   return (
//     <div className="app-container">
//       <header>
//         <button className="signup-btn">SignUp</button>
//       </header>
//       <div className="content">
//         <div className="card">
//           <div className="illustration">
//             {/* Placeholder for illustration (replace with actual image or SVG) */}
//             <div className="chart-icon"></div>
//             <div className="person-icon"></div>
//           </div>
//           <h2>Create a Campaign</h2>
//           <button className="action-btn">For Brands</button>
//         </div>
//         <div className="card">
//           <div className="illustration">
//             {/* Placeholder for illustration (replace with actual image or SVG) */}
//             <div className="camera-icon"></div>
//             <div className="desk-icon"></div>
//           </div>
//           <h2>Find Campaigns</h2>
//           <button className="action-btn">Influencers</button>
//         </div>
//       </div>
//     </div>
//   );
// }

// export default CampaignPage;





import React from 'react';
import { useNavigate } from 'react-router-dom';
import '../styles/CampaignPage.css';

function CampaignPage() {
  const navigate = useNavigate();

  return (
    <div className="app-container">
      <header>
        <button className="signup-btn" onClick={() => navigate('/signup-brand')}>
          SignUp
        </button>
        </header>
   <div className="content">
         <div className="card">
           <div className="illustration">
             {/* Placeholder for illustration (replace with actual image or SVG) */}
            <div className="chart-icon"></div>
                       <div className="person-icon"></div>
        </div>
        <h2>Create a Campaign</h2>
         <button className="action-btn">For Brands</button>
        </div>
      <div className="card">
          <div className="illustration">
            {/* Placeholder for illustration (replace with actual image or SVG) */}             <div className="camera-icon"></div>
            <div className="desk-icon"></div>
         </div>
         <h2>Find Campaigns</h2>
          <button className="action-btn">Influencers</button>
       </div>
      </div>
     </div>
   );
}

export default CampaignPage;
