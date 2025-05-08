import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://oeqhionlnztfutwnvrfq.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9lcWhpb25sbnp0ZnV0d252cmZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ5MDA0NjgsImV4cCI6MjA2MDQ3NjQ2OH0.IuH4Y2GO9WxfOAlMeOIbYnuLPKj4c61LEZvEpXUDfL4';
export const supabase = createClient(supabaseUrl, supabaseKey);