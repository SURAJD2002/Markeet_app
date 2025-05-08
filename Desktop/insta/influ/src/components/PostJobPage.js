import React, { useState } from 'react';
import { 
  FaBriefcase, 
  FaRegEdit, 
  FaDollarSign, 
  FaMoneyBillWave, 
  FaClock, 
  FaCalendarAlt,
  FaInstagram,
  FaFacebook,
  FaTwitter,
  FaLinkedin
} from 'react-icons/fa';
import '../styles/PostJobPage.css';

function PostJobPage() {
  const [formData, setFormData] = useState({
    roleTitle: '',
    roleDescription: '',
    requiredSkills: {
      contentCreation: false,
      communityManagement: false,
      paidAdvertising: false,
      analyticsReporting: false,
      strategyDevelopment: false,
      visualDesign: false,
    },
    platforms: {
      instagram: false,
      facebook: false,
      twitter: false,
      linkedin: false,
    },
    rateRange: '$30-$50/hour',
    paymentTerms: 'Hourly',
    weeklyHours: '10-20 hours',
    availability: 'Weekdays only',
  });

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    if (type === 'checkbox') {
      setFormData((prevState) => ({
        ...prevState,
        [name.split('.')[0]]: {
          ...prevState[name.split('.')[0]],
          [name.split('.')[1]]: checked,
        },
      }));
    } else {
      setFormData((prevState) => ({
        ...prevState,
        [name]: value,
      }));
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log('Form submitted:', formData);
    // Add submission logic here (e.g., API call)
  };

  return (
    <div className="post-job-page">
      {/* HEADER / NAV */}
      <header className="job-header">
        <div className="logo">JobBoard</div>
        <nav className="nav-links">
          <a href="#dashboard">Dashboard</a>
          <a href="#post-job" className="active">Post a Job</a>
          <a href="#my-posts">My Posts</a>
        </nav>
      </header>

      <main className="job-main">
        <h1 className="page-title">Post Social Media Manager Position</h1>
        <form className="job-form" onSubmit={handleSubmit}>
          {/* ROLE TITLE */}
          <div className="form-group">
            <label htmlFor="roleTitle" className="form-label">
              <FaBriefcase className="label-icon" /> Role Title
            </label>
            <input
              type="text"
              id="roleTitle"
              className="form-input"
              placeholder="e.g., Senior Social Media Manager"
              value={formData.roleTitle}
              onChange={handleChange}
              name="roleTitle"
              required
            />
          </div>

          {/* ROLE DESCRIPTION */}
          <div className="form-group">
            <label htmlFor="roleDescription" className="form-label">
              <FaRegEdit className="label-icon" /> Role Description
            </label>
            <textarea
              id="roleDescription"
              className="form-textarea"
              placeholder="Describe the role, responsibilities and requirements..."
              value={formData.roleDescription}
              onChange={handleChange}
              name="roleDescription"
              required
            />
          </div>

          {/* REQUIRED SKILLS (two-column layout) */}
          <div className="form-group">
            <label className="form-label">
              <FaBriefcase className="label-icon" /> Required Skills
            </label>
            <div className="two-column-checks">
              <div className="checkbox-column">
                <label>
                  <input
                    type="checkbox"
                    name="requiredSkills.contentCreation"
                    checked={formData.requiredSkills.contentCreation}
                    onChange={handleChange}
                  />{' '}
                  Content Creation
                </label>
                <label>
                  <input
                    type="checkbox"
                    name="requiredSkills.analyticsReporting"
                    checked={formData.requiredSkills.analyticsReporting}
                    onChange={handleChange}
                  />{' '}
                  Analytics & Reporting
                </label>
                <label>
                  <input
                    type="checkbox"
                    name="requiredSkills.strategyDevelopment"
                    checked={formData.requiredSkills.strategyDevelopment}
                    onChange={handleChange}
                  />{' '}
                  Strategy Development
                </label>
              </div>
              <div className="checkbox-column">
                <label>
                  <input
                    type="checkbox"
                    name="requiredSkills.communityManagement"
                    checked={formData.requiredSkills.communityManagement}
                    onChange={handleChange}
                  />{' '}
                  Community Management
                </label>
                <label>
                  <input
                    type="checkbox"
                    name="requiredSkills.paidAdvertising"
                    checked={formData.requiredSkills.paidAdvertising}
                    onChange={handleChange}
                  />{' '}
                  Paid Advertising
                </label>
                <label>
                  <input
                    type="checkbox"
                    name="requiredSkills.visualDesign"
                    checked={formData.requiredSkills.visualDesign}
                    onChange={handleChange}
                  />{' '}
                  Visual Design
                </label>
              </div>
            </div>
          </div>

          {/* PLATFORMS (two-column layout with icons) */}
          <div className="form-group">
            <label className="form-label">Platforms to Be Managed</label>
            <div className="two-column-checks">
              <div className="checkbox-column">
                <label>
                  <input
                    type="checkbox"
                    name="platforms.instagram"
                    checked={formData.platforms.instagram}
                    onChange={handleChange}
                  />{' '}
                  <FaInstagram className="platform-icon" /> Instagram
                </label>
                <label>
                  <input
                    type="checkbox"
                    name="platforms.twitter"
                    checked={formData.platforms.twitter}
                    onChange={handleChange}
                  />{' '}
                  <FaTwitter className="platform-icon" /> Twitter
                </label>
              </div>
              <div className="checkbox-column">
                <label>
                  <input
                    type="checkbox"
                    name="platforms.facebook"
                    checked={formData.platforms.facebook}
                    onChange={handleChange}
                  />{' '}
                  <FaFacebook className="platform-icon" /> Facebook
                </label>
                <label>
                  <input
                    type="checkbox"
                    name="platforms.linkedin"
                    checked={formData.platforms.linkedin}
                    onChange={handleChange}
                  />{' '}
                  <FaLinkedin className="platform-icon" /> LinkedIn
                </label>
              </div>
            </div>
          </div>

          {/* BUDGET/RATE ROW */}
          <div className="form-group multi-col">
            <div>
              <label htmlFor="rateRange" className="form-label">
                <FaDollarSign className="label-icon" /> Rate Range
              </label>
              <input
                type="text"
                id="rateRange"
                className="form-input"
                value={formData.rateRange}
                onChange={handleChange}
                name="rateRange"
                placeholder="$30-$50/hour"
              />
            </div>
            <div>
              <label htmlFor="paymentTerms" className="form-label">
                <FaMoneyBillWave className="label-icon" /> Payment Terms
              </label>
              <select
                id="paymentTerms"
                className="form-select"
                value={formData.paymentTerms}
                onChange={handleChange}
                name="paymentTerms"
              >
                <option>Hourly</option>
                <option>Monthly</option>
                <option>Project-based</option>
              </select>
            </div>
          </div>

          {/* SCHEDULE ROW */}
          <div className="form-group multi-col">
            <div>
              <label htmlFor="weeklyHours" className="form-label">
                <FaClock className="label-icon" /> Weekly Hours
              </label>
              <input
                type="text"
                id="weeklyHours"
                className="form-input"
                value={formData.weeklyHours}
                onChange={handleChange}
                name="weeklyHours"
                placeholder="10-20 hours"
              />
            </div>
            <div>
              <label htmlFor="availability" className="form-label">
                <FaCalendarAlt className="label-icon" /> Availability
              </label>
              <select
                id="availability"
                className="form-select"
                value={formData.availability}
                onChange={handleChange}
                name="availability"
              >
                <option value="">Select availability</option>
                <option value="Weekdays only">Weekdays only</option>
                <option value="Weekends only">Weekends only</option>
                <option value="Flexible">Flexible</option>
              </select>
            </div>
          </div>

          {/* SUBMIT BUTTON */}
          <div className="form-group">
            <button type="submit" className="post-job-btn">
              Post Position
            </button>
          </div>
        </form>
      </main>

      {/* FOOTER */}
      <footer className="job-footer">
        <p>© 2025 JobBoard. All rights reserved.</p>
        <div className="footer-links">
          <a href="#terms">Terms</a>
          <a href="#privacy">Privacy</a>
          <a href="#contact">Contact</a>
        </div>
      </footer>
    </div>
  );
}

export default PostJobPage;