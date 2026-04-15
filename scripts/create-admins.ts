import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

if (!supabaseUrl || !supabaseServiceKey) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env");
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function setupAdmins() {
  const admins = [
    { email: 'admin@kpsslingo.com', password: 'Password123!', username: 'admin', full_name: 'KPSSlingo Admin' },
    { email: 'multimicro14@gmail.com', password: 'Password123!', username: 'multimicro14', full_name: 'Master Admin' }
  ];

  for (const admin of admins) {
    console.log(`Processing admin: ${admin.email}`);
    
    // Check if user already exists
    const { data: existingUsers, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) {
      console.error("Error listing users:", listError.message);
      continue;
    }
    
    let user = existingUsers.users.find(u => u.email === admin.email);
    
    if (!user) {
      // Create user
      const { data: newUser, error } = await supabase.auth.admin.createUser({
        email: admin.email,
        password: admin.password,
        email_confirm: true,
        user_metadata: { role: 'admin' }
      });
      
      if (error) {
        console.error(`Error creating ${admin.email}:`, error.message);
        continue;
      }
      user = newUser.user;
      console.log(`Created user ${admin.email} with ID ${user.id}`);
    } else {
      // Update user to ensure role is admin
      const { data: updatedUser, error } = await supabase.auth.admin.updateUserById(user.id, {
        user_metadata: { ...user.user_metadata, role: 'admin' }
      });
      if (error) {
         console.error(`Error updating role for ${admin.email}:`, error.message);
         continue;
      }
      console.log(`Ensured role is admin for ${admin.email} (ID: ${user.id})`);
    }

    // Upsert into user_profiles
    const { error: profileError } = await supabase
      .from('user_profiles')
      .upsert({
        id: user.id,
        username: admin.username,
        full_name: admin.full_name,
        // Assuming there's total_xp, streak_days, variables that are fine left at default
      }, { onConflict: 'id' });
      
    if (profileError) {
      console.error(`Error upserting profile for ${admin.email}:`, profileError.message);
    } else {
      console.log(`Profile synced for ${admin.email}`);
    }
  }
}

setupAdmins();
