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

/**
 * GÜVENLİK UYARISI: Bu script hassas yetkilere sahip admin hesapları oluşturur.
 * Hardcoded şifreler kaldırılmıştır. Bilgileri .env dosyasından veya 
 * komut satırı argümanlarından alacak şekilde güncellenmiştir.
 */

async function setupAdmins() {
  const adminEmail = process.env.ADMIN_EMAIL;
  const adminPassword = process.env.ADMIN_PASSWORD;
  const adminUsername = process.env.ADMIN_USERNAME || 'admin';
  const adminFullName = process.env.ADMIN_FULL_NAME || 'KPSSlingo Admin';

  if (!adminEmail || !adminPassword) {
    console.log("----------------------------------------------------------------");
    console.log("BİLGİ: ADMIN_EMAIL ve ADMIN_PASSWORD credentials içinde bulunamadı.");
    console.log("Yeni bir admin oluşturmak için scripti şu şekilde çalıştırın:");
    console.log("ADMIN_EMAIL=test@test.com ADMIN_PASSWORD=Sifre123! npx ts-node scripts/create-admins.ts");
    console.log("----------------------------------------------------------------");
    return;
  }

  const admins = [
    {
      email: adminEmail,
      password: adminPassword,
      username: adminUsername,
      full_name: adminFullName
    }
  ];

  for (const admin of admins) {
    console.log(`Processing admin: ${admin.email}`);

    // Check if user already exists
    const { data: { users: existingUsers }, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) {
      console.error("Error listing users:", listError.message);
      continue;
    }

    let user = existingUsers.find(u => u.email === admin.email);

    if (!user) {
      // Create user
      const { data: newUser, error } = await supabase.auth.admin.createUser({
        email: admin.email,
        password: admin.password,
        email_confirm: true,
        user_metadata: { role: 'admin' }
      });

      if (error || !newUser.user) {
        console.error(`Error creating ${admin.email}:`, error?.message);
        continue;
      }
      user = newUser.user;
      console.log(`Created user ${admin.email} with ID ${user.id}`);
    } else {
      // Update user
      const { error } = await supabase.auth.admin.updateUserById(user.id, {
        password: admin.password, // Update password if provided
        user_metadata: { ...user.user_metadata, role: 'admin' }
      });
      if (error) {
        console.error(`Error updating user ${admin.email}:`, error.message);
        continue;
      }
      console.log(`Updated user ${admin.email} (ID: ${user.id})`);
    }

    // 1. Sync into user_roles table (Single Source of Truth)
    const { error: roleError } = await supabase
      .from('user_roles')
      .upsert({
        user_id: user.id,
        role: 'admin',
      }, { onConflict: 'user_id' });

    if (roleError) {
      console.error(`Error syncing role for ${admin.email}:`, roleError.message);
    } else {
      console.log(`Role 'admin' synced for ${admin.email}`);
    }

    // 2. Upsert into user_profiles
    const { error: profileError } = await supabase
      .from('user_profiles')
      .upsert({
        id: user.id,
        username: admin.username,
        full_name: admin.full_name,
      }, { onConflict: 'id' });

    if (profileError) {
      console.error(`Error upserting profile for ${admin.email}:`, profileError.message);
    } else {
      console.log(`Profile synced for ${admin.email}`);
    }
  }
}

setupAdmins();
