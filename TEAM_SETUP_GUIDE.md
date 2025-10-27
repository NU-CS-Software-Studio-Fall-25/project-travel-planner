# Team Setup Guide - Prevent Database Sync Issues

## 🚨 The Problem

When you merge changes that modify the database structure, your teammates get errors because:
1. Their local database doesn't have the new schema changes
2. They need to run migrations but might not know which ones
3. The database might have stale data that conflicts with new constraints

## ✅ What's Already Set Up Correctly

Good news! Your project is already configured properly:
- ✅ SQLite database files are ignored by git (not committed)
- ✅ Migration files ARE tracked in git (this is correct)
- ✅ `schema.rb` IS tracked in git (this is correct)

## 📋 Standard Workflow for Team Members

### When Pulling Changes That Modify the Database:

**Run this command after pulling from main:**
```bash
bin/rails db:migrate
```

If you get errors, try the full reset:
```bash
bin/rails db:migrate:reset
bin/rails db:seed
```

### When You Create New Migrations:

1. **Create your migration:**
   ```bash
   rails generate migration AddFieldToModel field:type
   ```

2. **Run the migration locally:**
   ```bash
   rails db:migrate
   ```

3. **Commit BOTH the migration file AND schema.rb:**
   ```bash
   git add db/migrate/*
   git add db/schema.rb
   git commit -m "Add migration: description of changes"
   git push
   ```

## 🛠️ Quick Fix Commands

### For Teammates After You Merge:

```bash
# Pull latest changes
git pull origin main

# Update dependencies (if Gemfile changed)
bundle install

# Run pending migrations
rails db:migrate

# If you get errors, reset the database
rails db:migrate:reset
rails db:seed

# Restart your server
rails s
```

### If Database Gets Corrupted:

```bash
# Drop, recreate, migrate, and seed
rails db:reset

# Or manually:
rails db:drop
rails db:create
rails db:migrate
rails db:seed
```

## 🔄 Automated Solution

I've created a helper script to make this easier. See `bin/setup_database` below.

## 📝 Best Practices

### DO:
- ✅ Always commit `db/schema.rb` with your migrations
- ✅ Run `rails db:migrate` after pulling
- ✅ Notify team when merging database changes
- ✅ Test migrations before committing
- ✅ Use descriptive migration names

### DON'T:
- ❌ Edit `schema.rb` manually (it's auto-generated)
- ❌ Commit `.sqlite3` database files
- ❌ Skip migrations when pulling changes
- ❌ Delete migration files after running them
- ❌ Modify old migration files (create new ones instead)

## 🚀 Quick Reference

| Situation | Command |
|-----------|---------|
| Just pulled changes | `rails db:migrate` |
| Database is broken | `rails db:reset` |
| Need fresh start | `rails db:drop db:create db:migrate db:seed` |
| Check migration status | `rails db:migrate:status` |
| Created new migration | Commit both `db/migrate/*` and `db/schema.rb` |

## 🎯 Git Workflow with Database Changes

```bash
# 1. Pull latest
git pull origin main

# 2. Update database
rails db:migrate

# 3. Make your changes...
# (create migrations, modify models, etc.)

# 4. Run your new migrations
rails db:migrate

# 5. Check what changed
git status
# Should see: db/schema.rb and db/migrate/[timestamp]_*.rb

# 6. Commit everything
git add .
git commit -m "Add feature X with database migration"
git push

# 7. Notify team!
```

## 💡 Pro Tips

1. **Check migration status anytime:**
   ```bash
   rails db:migrate:status
   ```

2. **Rollback last migration if needed:**
   ```bash
   rails db:rollback
   ```

3. **See what migrations are pending:**
   ```bash
   rails db:migrate:status | grep "down"
   ```

4. **Seed data for testing:**
   ```bash
   rails db:seed
   ```

## 🆘 Troubleshooting

### "PendingMigrationError"
```bash
rails db:migrate
```

### "Table already exists"
```bash
rails db:drop db:create db:migrate db:seed
```

### "SQLite3::ConstraintException"
```bash
rails db:reset
```

### "Migrations are pending"
```bash
rails db:migrate
rails db:test:prepare  # for test database
```

## 📞 Need Help?

If you're stuck:
1. Check `rails db:migrate:status`
2. Try `rails db:reset`
3. Ask in the team chat
4. Check this guide again!

---

**Remember:** Communication is key! Always let your team know when you merge database changes. 🎉
