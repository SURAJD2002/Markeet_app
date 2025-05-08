import React from 'react';
import '../styles/PricingPage.css';
import { Link } from 'react-router-dom';
import homeBackground from '../assets/homebackgorund.jpg'; // Corrected typo

function PricingPage() {
  const plans = [
    {
      title: 'Starter',
      price: '$16.67 USD/month*',
      billed: 'billed yearly, 14-Day Free Trial',
      features: [
        '1 Social Set profile',
        '1 User',
        'Schedule up to 30 posts per profile',
        '1 AI content assistant credit / 3 months of data',
        '1 brand code for creators',
      ],
    },
    {
      title: 'Starter',
      price: '$16.67 USD/month*',
      billed: 'billed yearly, 14-Day Free Trial',
      features: [
        '1 Social Set profile',
        '1 User',
        'Schedule up to 30 posts per profile',
        '1 AI content assistant credit / 3 months of data',
        '1 brand code for creators',
      ],
    },
    {
      title: 'Starter',
      price: '$16.67 USD/month*',
      billed: 'billed yearly, 14-Day Free Trial',
      features: [
        '1 Social Set profile',
        '1 User',
        'Schedule up to 30 posts per profile',
        '1 AI content assistant credit / 3 months of data',
        '1 brand code for creators',
      ],
    },
    {
      title: 'Starter',
      price: '$16.67 USD/month*',
      billed: 'billed yearly, 14-Day Free Trial',
      features: [
        '1 Social Set profile',
        '1 User',
        'Schedule up to 30 posts per profile',
        '1 AI content assistant credit / 3 months of data',
        '1 brand code for creators',
      ],
    },
    {
      title: 'Starter',
      price: '$16.67 USD/month*',
      billed: 'billed yearly, 14-Day Free Trial',
      features: [
        '1 Social Set profile',
        '1 User',
        'Schedule up to 30 posts per profile',
        '1 AI content assistant credit / 3 months of data',
        '1 brand code for creators',
      ],
    },
  ];

  return (
    <div className="pricing-page" style={{ backgroundImage: `url(${homeBackground})` }}>
      <header className="pricing-header">
        <h1>Find a suitable plan</h1>
        <span className="callout">A</span>
      </header>
      <div className="plans-container">
        {plans.map((plan, index) => (
          <div className="plan-card" key={index}>
            <h3>{plan.title}</h3>
            <p className="price">{plan.price}</p>
            <p className="billed">{plan.billed}</p>
            <ul>
              {plan.features.map((feature, i) => (
                <li key={i}>{feature}</li>
              ))}
            </ul>
            <button className="try-now-btn">Try Now</button>
          </div>
        ))}
      </div>
      <div className="footer-text">
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam eu turpis molestie, dictum est a, mattis tellus. Sed dignissim, metus nec fringilla accumsan, risus sem sollicitudin lacus, ut interdum tellus elit sed risus. Maecenas eget condimentum velit, sit amet feugiat lectus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Praesent auctor purus luctus enim egestas, ac scelerisque enim facilisis. In hac habitasse platea dictumst. Etiam fermentum viverra aliquet. Ut semper vulputate urna.</p>
        <p>Curabitur tempus quis eros tempus lacinia. Nam bibendum mollis arcu vitae blandit. Nunc consequat magna et sapien malesuada, eu pulvinar magna lacinia. Suspendisse quis eros tempus lacinia. Nam bibendum mollis arcu vitae blandit. Nunc consequat magna et sapien malesuada, eu pulvinar magna lacinia. Suspendisse quis eros tempus lacinia. Nam bibendum mollis arcu vitae blandit. Nunc consequat magna et sapien malesuada, eu pulvinar magna lacinia.</p>
      </div>
    </div>
  );
}

export default PricingPage;