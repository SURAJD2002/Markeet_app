// import React from 'react';
// import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
// import Navbar from './components/Navbar';
// import HomePage from './components/HomePage';
// import AboutPage from './components/AboutPage';
// import CampaignPage from './components/CampaignPage';
// import LoginPage from './components/LoginPage';
// import SignupBrandPage from './components/SignupBrandPage';
// import SignupInfluencerPage from './components/SignupInfluencerPage';
// import PricingPage from './components/PricingPage';
// import InfluencerDashboard from './components/InfluencerDashboard';
// import InfluencerProfileSetup from './components/InfluencerProfileSetup';
// import BrandDashboard from './components/BrandDashboard';
// import CreateCampaign from './components/CreateCampaign';
// import InfluencerSearchPage from './components/InfluencerSearchPage';
// import InfluencerProfilePublic from './components/InfluencerProfilePublic';
// import PostJobPage from './components/PostJobPage';
// import ContentCalendar from './components/ContentCalendar';
// import AnalyticsDashboard from './components/AnalyticsDashboard';
// import CampaignListingPage from './components/CampaignListingPage';
// import CampaignDetailsPage from './components/CampaignDetailsPage';

// import './App.css';

// function App() {
//   return (
//     <Router>
//       <div className="App">
//         {/* Navbar is displayed on all pages */}
//         <Navbar />
//         <Routes>
//           <Route path="/" element={<HomePage />} />
//           <Route path="/campaign" element={<CampaignPage />} />
//           <Route path="/login" element={<LoginPage />} />
//           <Route path="/signup-brand" element={<SignupBrandPage />} />
//           <Route path="/signup-influencer" element={<SignupInfluencerPage />} />
//           <Route path="/pricing" element={<PricingPage />} />
//           <Route path="/about" element={<AboutPage />} />
//           <Route path="/post-job" element={<PostJobPage />} />
//           <Route path="/dashboard" element={<InfluencerDashboard />} />
//           <Route path="/profile-setup" element={<InfluencerProfileSetup />} />
//           <Route path="/resources" element={<div>Resources Page</div>} />
//           <Route path="/how-it-works" element={<div>How It Works</div>} />
//           <Route path="/influencer-profile" element={<InfluencerProfilePublic />} />
//           <Route path="/brand-dashboard" element={<BrandDashboard />} />
//           <Route path="/for-brands" element={<div>For Brands</div>} />
//           <Route path="/for-influencers" element={<div>For Influencers</div>} />
//           <Route path="/content-calendar" element={<ContentCalendar />} />
//           <Route path="/create-campaign" element={<CreateCampaign />} />
//           <Route path="/search-influencers" element={<InfluencerSearchPage />} />
//           <Route path="/campaign/:id" element={<CampaignDetailsPage />} />
//           <Route path="/analytics" element={<AnalyticsDashboard />} />
//           <Route path="/CampaignListingPage" element={<CampaignListingPage />} />
//         </Routes>
//       </div>
//     </Router>
//   );
// }

// export default App;




import React from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import Navbar from './components/Navbar';
import HomePage from './components/HomePage';
import AboutPage from './components/AboutPage';
import CampaignPage from './components/CampaignPage';
import LoginPage from './components/LoginPage';
import SignupBrandPage from './components/SignupBrandPage';
import SignupInfluencerPage from './components/SignupInfluencerPage';
import PricingPage from './components/PricingPage';
import InfluencerDashboard from './components/InfluencerDashboard';
import InfluencerProfileSetup from './components/InfluencerProfileSetup';
import BrandDashboard from './components/BrandDashboard';
import CreateCampaign from './components/CreateCampaign';
import InfluencerSearchPage from './components/InfluencerSearchPage';
import InfluencerProfilePublic from './components/InfluencerProfilePublic';
import PostJobPage from './components/PostJobPage';
import ContentCalendar from './components/ContentCalendar';
import AnalyticsDashboard from './components/AnalyticsDashboard';
import CampaignListingPage from './components/CampaignListingPage';
import CampaignDetailsPage from './components/CampaignDetailsPage';

import './App.css';

// Wrapper component to handle conditional rendering of Navbar
function AppContent() {
  const location = useLocation();
  // Define routes where the sidebar should be hidden
  const hideSidebarRoutes = [
    '/login',
    '/signup-brand',
    '/signup-influencer',
    '/',
    '/about',
    '/pricing',
    '/campaign',
    '/resources',
    '/how-it-works',
    '/for-brands',
    '/for-influencers',
    '/post-job',
    '/influencer-profile',
  ];
  const shouldShowSidebar = !hideSidebarRoutes.includes(location.pathname);

  return (
    <div className="App">
      {shouldShowSidebar && <Navbar />}
      <main className={shouldShowSidebar ? 'main-content' : 'main-content-full'}>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/campaign" element={<CampaignPage />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/signup-brand" element={<SignupBrandPage />} />
          <Route path="/signup-influencer" element={<SignupInfluencerPage />} />
          <Route path="/pricing" element={<PricingPage />} />
          <Route path="/about" element={<AboutPage />} />
          <Route path="/post-job" element={<PostJobPage />} />
          <Route path="/dashboard" element={<InfluencerDashboard />} />
          <Route path="/profile-setup" element={<InfluencerProfileSetup />} />
          <Route path="/resources" element={<div>Resources Page</div>} />
          <Route path="/how-it-works" element={<div>How It Works</div>} />
          <Route path="/influencer-profile" element={<InfluencerProfilePublic />} />
          <Route path="/brand-dashboard" element={<BrandDashboard />} />
          <Route path="/for-brands" element={<div>For Brands</div>} />
          <Route path="/for-influencers" element={<div>For Influencers</div>} />
          <Route path="/content-calendar" element={<ContentCalendar />} />
          <Route path="/create-campaign" element={<CreateCampaign />} />
          <Route path="/search-influencers" element={<InfluencerSearchPage />} />
          <Route path="/campaign/:id" element={<CampaignDetailsPage />} />
          <Route path="/analytics" element={<AnalyticsDashboard />} />
          <Route path="/CampaignListingPage" element={<CampaignListingPage />} />
          <Route path="/earnings" element={<div>Earnings Page</div>} />
          <Route path="/settings" element={<div>Settings Page</div>} />
        </Routes>
      </main>
    </div>
  );
}

function App() {
  return (
    <Router>
      <AppContent />
    </Router>
  );
}

export default App;