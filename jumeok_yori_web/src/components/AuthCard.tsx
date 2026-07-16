export function AuthCard({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mx-auto flex min-h-[70vh] max-w-md flex-col justify-center px-4 py-12 sm:px-6">
      <div className="rounded-3xl border border-soft-gray bg-white p-8 shadow-sm">
        <h1 className="text-2xl font-extrabold text-dark-ink">{title}</h1>
        {subtitle && <p className="mt-2 text-sm text-text-gray">{subtitle}</p>}
        <div className="mt-6">{children}</div>
      </div>
    </div>
  );
}

export function FormField({
  label,
  ...props
}: React.InputHTMLAttributes<HTMLInputElement> & { label: string }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-sm font-semibold text-dark-ink">{label}</span>
      <input
        {...props}
        className="w-full rounded-xl border border-soft-gray bg-white px-4 py-3 text-sm outline-none transition focus:border-orange"
      />
    </label>
  );
}

export function SubmitButton({
  loading,
  children,
}: {
  loading: boolean;
  children: React.ReactNode;
}) {
  return (
    <button
      type="submit"
      disabled={loading}
      className="mt-2 flex h-13 w-full items-center justify-center rounded-xl bg-orange py-3.5 text-base font-bold text-white transition hover:opacity-90 disabled:opacity-50"
    >
      {loading ? "처리 중..." : children}
    </button>
  );
}
