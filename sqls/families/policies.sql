create policy "Individuals can view their own families."
on families for select
using ( (select auth.uid()) = created_by );