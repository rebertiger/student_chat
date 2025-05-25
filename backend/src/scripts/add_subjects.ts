import pool from '../db';

const subjects = [
  {
    name: 'Introduction to Computer Science',
    description: 'Fundamental concepts of computer science and programming'
  },
  {
    name: 'Data Structures and Algorithms',
    description: 'Study of fundamental data structures and algorithm design'
  },
  {
    name: 'Database Systems',
    description: 'Design and implementation of database systems'
  },
  {
    name: 'Software Engineering',
    description: 'Principles and practices of software development'
  },
  {
    name: 'Operating Systems',
    description: 'Study of operating system concepts and implementation'
  },
  {
    name: 'Computer Networks',
    description: 'Fundamentals of computer networking and protocols'
  },
  {
    name: 'Artificial Intelligence',
    description: 'Introduction to AI concepts and machine learning'
  },
  {
    name: 'Web Development',
    description: 'Modern web development technologies and practices'
  }
];

async function addSubjects() {
  try {
    for (const subject of subjects) {
      await pool.query(
        'INSERT INTO subjects (name, description) VALUES ($1, $2)',
        [subject.name, subject.description]
      );
      console.log(`Added subject: ${subject.name}`);
    }
    console.log('All subjects added successfully');
  } catch (error) {
    console.error('Error adding subjects:', error);
  } finally {
    await pool.end();
  }
}

addSubjects(); 