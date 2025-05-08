import React from 'react';
import '../styles/AboutPage.css';
import { Link } from 'react-router-dom';
import homeBackground from '../assets/homebackgorund.jpg';

function AboutPage() {
  const faqs = [
    { question: 'Question here' },
    { question: 'Question here' },
    { question: 'Question here' },
    { question: 'Question here' },
  ];

  return (
    <div className="about-page" style={{ backgroundImage: `url(${homeBackground})` }}>
      <header className="about-header">
        <h1>About name</h1>
      </header>
      <section className="image-section">
        <img src="https://via.placeholder.com/600x400" alt="Team working" />
      </section>
      <section className="text-section">
        <p>
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam eu turpis molestie, dictum est a, mattis tellus. Sed
          dignissim, metus nec fringilla accumsan, risus sem sollicitudin lacus, ut interdum tellus elit sed risus. Maecenas
          eget condimentum velit, sit amet feugiat lectus. Class aptent taciti sociosqu ad litora torquent per conubia nostra,
          per inceptos himenaeos. Praesent auctor purus luctus enim egestas, ac scelerisque enim facilisis. In hac habitasse
          platea dictumst. Etiam fermentum viverra aliquet. Ut semper vulputate urna.
        </p>
        <p>
          Curabitur tempus quis eros tempus lacinia. Nam bibendum mollis arcu vitae blandit. Nunc consequat magna et sapien
          malesuada, eu pulvinar magna lacinia. Suspendisse quis eros tempus lacinia. Nam bibendum mollis arcu vitae blandit.
          Nunc consequat magna et sapien malesuada, eu pulvinar magna lacinia. Suspendisse quis eros tempus lacinia. Nam
          bibendum mollis arcu vitae blandit. Nunc consequat magna et sapien malesuada, eu pulvinar magna lacinia.
        </p>
      </section>
      <section className="faq-section">
        <h2>FAQs</h2>
        {faqs.map((faq, index) => (
          <div className="faq-item" key={index}>
            <p>{faq.question}</p>
            <span className="faq-check">✔</span>
          </div>
        ))}
      </section>
    </div>
  );
}

export default AboutPage;