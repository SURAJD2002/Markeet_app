import React from 'react';
import SignupBrandPage from '../components/SignupBrandPage';
import SignupInfluencerPage from '../components/SignupInfluencerPage';
import '..styles/SignUpWrapper.css';

function SignUpWrapper() {
  return (
    <div className="signup-wrapper">
      <SignupBrandPage />
      <SignupInfluencerPage />
    </div>
  );
}

export default SignUpWrapper;
