import React from 'react';
import { FaCamera, FaInstagram, FaLinkedin } from 'react-icons/fa';
import { SiTiktok } from 'react-icons/si';
import '../styles/InfluencerProfileSetup.css';

function InfluencerProfileSetup() {
  const handleSubmit = (e) => {
    e.preventDefault();
    // Submit logic here
    console.log('Profile saved');
  };

  const handlePreview = () => {
    // Preview logic
    console.log('Preview profile');
  };

  return (
    <div className="profile-setup-container">
      <h1 className="profile-setup-title">Create Your Influencer Profile</h1>
      <p className="profile-setup-subtitle">
        Complete your profile to start connecting with brands
      </p>

      <form className="profile-setup-form" onSubmit={handleSubmit}>
        {/* Profile Photo with Camera Icon */}
        <div className="form-group">
          <label className="form-label" htmlFor="profilePhoto">
            <FaCamera className="upload-icon" />
            Profile Photo
          </label>
          <input
            type="file"
            id="profilePhoto"
            className="form-input"
            accept="image/*"
          />
        </div>

        {/* Bio */}
        <div className="form-group">
          <label className="form-label" htmlFor="bio">
            Bio
          </label>
          <textarea
            id="bio"
            className="form-textarea"
            placeholder="Tell us about yourself..."
            rows="4"
          ></textarea>
        </div>

        {/* Niche Selection */}
        <h2 className="section-heading">Your Niche</h2>
        <div className="niche-group">
          <div className="form-group">
            <label className="form-label" htmlFor="primaryNiche">
              Select primary niche
            </label>
            <select id="primaryNiche" className="form-select">
              <option value="" disabled hidden>
                Select primary niche
              </option>
              <option>Fashion</option>
              <option>Beauty</option>
              <option>Lifestyle</option>
              <option>Fitness</option>
              <option>Travel</option>
              <option>Other</option>
            </select>
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="secondaryNiche">
              Select secondary niche
            </label>
            <select id="secondaryNiche" className="form-select">
              <option value="" disabled hidden>
                Select secondary niche
              </option>
              <option>Fashion</option>
              <option>Beauty</option>
              <option>Lifestyle</option>
              <option>Fitness</option>
              <option>Travel</option>
              <option>Other</option>
            </select>
          </div>
        </div>

        {/* Social Media Accounts with Icons */}
        <h2 className="section-heading">Social Media Accounts</h2>
        <div className="form-group">
          <label className="form-label" htmlFor="instagramHandle">
            <FaInstagram className="social-icon" />
            Instagram username
          </label>
          <input
            type="text"
            id="instagramHandle"
            className="form-input"
            placeholder="@username"
          />
        </div>
        <div className="form-group">
          <label className="form-label" htmlFor="tiktokHandle">
            <SiTiktok className="social-icon" />
            TikTok username
          </label>
          <input
            type="text"
            id="tiktokHandle"
            className="form-input"
            placeholder="@username"
          />
        </div>
        <div className="form-group">
          <label className="form-label" htmlFor="linkedinUrl">
            <FaLinkedin className="social-icon" />
            LinkedIn profile URL
          </label>
          <input
            type="text"
            id="linkedinUrl"
            className="form-input"
            placeholder="LinkedIn profile URL"
          />
        </div>

        {/* Services Offered */}
        <h2 className="section-heading">Services Offered</h2>
        <div className="checkbox-group">
          <label className="checkbox-label">
            <input type="checkbox" name="services" value="Sponsored Posts" />
            Sponsored Posts
          </label>
          <label className="checkbox-label">
            <input type="checkbox" name="services" value="Product Reviews" />
            Product Reviews
          </label>
          <label className="checkbox-label">
            <input type="checkbox" name="services" value="Event Appearances" />
            Event Appearances
          </label>
          <label className="checkbox-label">
            <input type="checkbox" name="services" value="Brand Ambassador" />
            Brand Ambassador
          </label>
          <label className="checkbox-label">
            <input type="checkbox" name="services" value="Consultation" />
            Consultation
          </label>
          <label className="checkbox-label">
            <input type="checkbox" name="services" value="Custom Content" />
            Custom Content
          </label>
        </div>

        {/* Buttons */}
        <div className="buttons-row">
          <button type="button" className="preview-btn" onClick={handlePreview}>
            Preview
          </button>
          <button type="submit" className="save-btn">
            Save Profile
          </button>
        </div>
      </form>
    </div>
  );
}

export default InfluencerProfileSetup;
