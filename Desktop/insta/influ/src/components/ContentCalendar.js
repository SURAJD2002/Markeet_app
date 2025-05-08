import React from 'react';
import { FaChevronLeft, FaChevronRight, FaCheck, FaEdit, FaInstagram, FaCalendarAlt, FaUser } from 'react-icons/fa';
import '../styles/ContentCalendar.css';

function ContentCalendar() {
  const post = {
    date: 'Dec 2, 2025 10:00 AM',
    status: 'Pending',
    text: 'Check out our latest collection for the winter season! #Fashion #Winter2025',
    mediaUrl: '', // Provide real URL if needed
    platform: 'Instagram',
  };

  return (
    <div className="calendar-container">
      {/* HEADER */}
      <header className="calendar-header">
        <div className="header-left">
          <button className="month-nav-btn">
            <FaChevronLeft />
          </button>
          <h1 className="calendar-title">December 2025</h1>
          <button className="month-nav-btn">
            <FaChevronRight />
          </button>
        </div>
        <div className="header-right">
          <button className="toggle-btn">
            <FaCalendarAlt /> Month
          </button>
          <button className="toggle-btn">
            <FaUser /> Team
          </button>
        </div>
      </header>

      {/* MAIN CONTENT */}
      <div className="calendar-main">
        {/* CALENDAR SECTION */}
        <section className="calendar-view">
          <div className="calendar-topbar">
            <h2 className="calendar-title">Content Calendar</h2>
            <button className="today-btn">Today</button>
          </div>
          {/* Weekdays Row */}
          <div className="weekdays-row">
            {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
              <span key={day}>{day}</span>
            ))}
          </div>
          {/* Calendar Rows */}
          <div className="calendar-grid">
            {Array.from({ length: 5 }, (_, weekIndex) => (
              <div key={weekIndex} className="calendar-row">
                {Array.from({ length: 7 }, (_, dayIndex) => {
                  const day = weekIndex * 7 + dayIndex + 1;
                  return day <= 31 ? (
                    <div key={day} className="calendar-cell">
                      <div className="day-number">{day}</div>
                      {day === 2 && (
                        <div className="calendar-post instagram-post">
                          <FaInstagram /> Instagram Post
                        </div>
                      )}
                    </div>
                  ) : (
                    <div key={day} className="calendar-cell"></div>
                  );
                })}
              </div>
            ))}
          </div>
        </section>

        {/* CONTENT REVIEW SECTION */}
        <aside className="content-review">
          <div className="review-header">
            <h3>Content Review</h3>
            <span className={`status-badge ${post.status.toLowerCase()}`}>
              {post.status}
            </span>
          </div>
          <div className="review-body">
            <label className="review-label">Post Text</label>
            <p className="post-text">{post.text}</p>
            <label className="review-label">Media</label>
            {post.mediaUrl ? (
              <img src={post.mediaUrl} alt="Post Media" className="post-media" />
            ) : (
              <div className="media-placeholder">📷 No media uploaded</div>
            )}
            <div className="schedule-info">
              <p className="schedule-time">📅 Scheduled for {post.date}</p>
              <p className="platform-tag">📱 {post.platform}</p>
            </div>
            <div className="review-actions">
              <button className="approve-btn">
                <FaCheck /> Approve
              </button>
              <button className="request-btn">
                <FaEdit /> Request Edits
              </button>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}

export default ContentCalendar;