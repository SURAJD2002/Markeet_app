import React from 'react';
import { FaInstagram, FaTiktok } from 'react-icons/fa';
import '../styles/CampaignDetailsPage.css';

const CampaignDetailsPage = () => {
  const campaign = {
    title: 'Summer Collection Launch',
    brand: 'Fashion Brand Co.',
    categories: ['Fashion', 'Lifestyle'],
    status: 'Active Campaign',
    posted: 'Posted 2 days ago',
    budget: '$2,500',
    applicants: '15 influencers have applied',
    objective:
      "Launch our new summer collection with a focus on sustainable fashion and beachwear. We're looking for authentic content that showcases our products in real-life settings while highlighting our commitment to eco-friendly materials.",
    contentRequirements: {
      type: '2 Instagram Posts + 3 Stories + 1 Reel',
      tags: '#SustainableFashion #SummerCollection2025 #FashionBrandCo',
      guidelines: 'Bright, summer vibes with a focus on lifestyle and sustainability',
    },
    deliverablesTimeline: {
      duration: 'May 1 - June 30, 2025',
      contentDeadline: 'First post by May 15, 2025',
    },
    requirements: {
      minFollowers: '50K+',
      engagementRate: '3%+',
      location: 'United States',
    },
    platforms: ['Instagram', 'TikTok'],
    previousSuccess: {
      avgEngagement: '4.8%',
      totalReach: '2.5M+',
      contentCreated: '150+ posts',
    },
  };

  return (
    <div className="campaign-details-page">
      {/* Header */}
      <header className="campaign-header">
        <div className="campaign-header-left">
          <div className="campaign-brand-logo">🧑‍💼</div>
          <div>
            <h1 className="campaign-title">{campaign.title}</h1>
            <p className="campaign-brand">by {campaign.brand}</p>
          </div>
        </div>
        <div className="campaign-header-right">
          <span className="campaign-status">{campaign.status}</span>
          <span className="campaign-posted">{campaign.posted}</span>
        </div>
      </header>

      {/* Categories */}
      <div className="campaign-categories">
        {campaign.categories.map((category, index) => (
          <span key={index} className="category-tag">
            {category}
          </span>
        ))}
      </div>

      {/* Main Content */}
      <div className="campaign-content">
        {/* Left Column */}
        <div className="campaign-content-left">
          <section className="campaign-section">
            <h2>Campaign Objective</h2>
            <p>{campaign.objective}</p>
          </section>

          <section className="campaign-section">
            <h2>Content Requirements</h2>
            <div className="content-requirement">
              <span className="content-label">Content Type</span>
              <p>{campaign.contentRequirements.type}</p>
            </div>
            <div className="content-requirement">
              <span className="content-label">Required Tags</span>
              <p>{campaign.contentRequirements.tags}</p>
            </div>
            <div className="content-requirement">
              <span className="content-label">Style Guidelines</span>
              <p>{campaign.contentRequirements.guidelines}</p>
            </div>
          </section>

          <section className="campaign-section">
            <h2>Deliverables & Timeline</h2>
            <div className="timeline-item">
              <span className="timeline-label">Campaign Duration</span>
              <p>{campaign.deliverablesTimeline.duration}</p>
            </div>
            <div className="timeline-item">
              <span className="timeline-label">Content Deadline</span>
              <p>{campaign.deliverablesTimeline.contentDeadline}</p>
            </div>
          </section>
        </div>

        {/* Right Column */}
        <div className="campaign-content-right">
          <section className="campaign-budget">
            <h1>{campaign.budget}</h1>
            <p>Fixed Payment</p>
            <button className="apply-button">Apply Now</button>
            <p className="applicants">{campaign.applicants}</p>
          </section>

          <section className="campaign-section">
            <h2>Requirements</h2>
            <div className="requirement-item">
              <span className="requirement-label">Min Followers</span>
              <p>{campaign.requirements.minFollowers}</p>
            </div>
            <div className="requirement-item">
              <span className="requirement-label">Engagement Rate</span>
              <p>{campaign.requirements.engagementRate}</p>
            </div>
            <div className="requirement-item">
              <span className="requirement-label">Location</span>
              <p>{campaign.requirements.location}</p>
            </div>
          </section>

          <section className="campaign-section">
            <h2>Required Platforms</h2>
            <div className="platforms">
              {campaign.platforms.map((platform, index) => (
                <span key={index} className="platform-tag">
                  {platform === 'Instagram' && <FaInstagram />}
                  {platform === 'TikTok' && <FaTiktok />}
                  {platform}
                </span>
              ))}
            </div>
          </section>

          <section className="campaign-section">
            <h2>Previous Campaign Success</h2>
            <div className="success-item">
              <span className="success-label">Average Engagement</span>
              <p>{campaign.previousSuccess.avgEngagement}</p>
            </div>
            <div className="success-item">
              <span className="success-label">Total Reach</span>
              <p>{campaign.previousSuccess.totalReach}</p>
            </div>
            <div className="success-item">
              <span className="success-label">Content Created</span>
              <p>{campaign.previousSuccess.contentCreated}</p>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
};

export default CampaignDetailsPage;