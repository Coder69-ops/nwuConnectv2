
export const DEPARTMENTS = [
    'CSE',
    'EEE',
    'ECE',
    'Civil Engineering',
    'Business Administration',
    'Law',
    'English',
    'Economics',
    'Sociology',
    'Development Studies',
    'Public Health',
] as const;

export type Department = typeof DEPARTMENTS[number];
