const modules = [
  {
    number: "01",
    title: "Matchmaking społeczny",
    description:
      "Łączy zgłaszane problemy społeczne z gotowymi innowacjami i uzasadnia dopasowanie.",
    required: true,
  },
  {
    number: "02",
    title: "Zasobnik wiedzy",
    description:
      "Mapa Wyzwań Społecznych, raporty, Biblioteka Innowacji i materiały edukacyjne.",
  },
  {
    number: "03",
    title: "Kreator pomysłów",
    description:
      "Zgłaszanie nowych pomysłów, dobre praktyki oraz generator wniosków w czasie naborów.",
  },
  {
    number: "04",
    title: "Tester innowacji",
    description:
      "Zgłoszenie do testów, ocena rozwiązań i przekazywanie informacji zwrotnej.",
  },
  {
    number: "05",
    title: "Middleman innowacji",
    description:
      "Asystent AI pomaga dostosować innowację do potrzeb instytucji zgłaszającej.",
  },
  {
    number: "06",
    title: "Platforma aktywnej komunikacji",
    description:
      "Dialog z ROPS, wsparcie mentorów i budowanie międzysektorowych partnerstw.",
  },
  {
    number: "07",
    title: "Panel administratora",
    description:
      "Szybka weryfikacja, modyfikacja i udostępnianie wiedzy przez pracowników Hubu.",
  },
];

export default function Home() {
  return (
    <div className="flex min-h-full flex-1 flex-col bg-slate-50 text-slate-900">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex w-full max-w-6xl items-center justify-between gap-4 px-6 py-4">
          <span className="flex items-center gap-3">
            <span
              aria-hidden="true"
              className="grid h-10 w-10 place-items-center rounded-xl bg-indigo-600 text-lg font-bold text-white"
            >
              H
            </span>
            <span className="text-lg font-semibold tracking-tight">
              HubMI
              <span className="text-indigo-600">.pl</span>
            </span>
          </span>
          <span className="rounded-full border border-indigo-200 bg-indigo-50 px-3 py-1 text-xs font-medium text-indigo-700">
            Prototyp MVP · HackYeah 2026
          </span>
        </div>
      </header>

      <main className="mx-auto w-full max-w-6xl flex-1 px-6">
        <section className="py-16 text-center sm:py-24">
          <p className="mb-4 text-sm font-semibold uppercase tracking-[0.2em] text-indigo-600">
            Od empatii do technologii
          </p>
          <h1 className="mx-auto max-w-4xl text-balance text-4xl font-bold leading-tight tracking-tight sm:text-5xl md:text-6xl">
            Małopolski Hub Innowacji Społecznych
          </h1>
          <p className="mx-auto mt-6 max-w-2xl text-pretty text-lg leading-relaxed text-slate-600">
            Regionalny ekosystem, który łączy potrzeby społeczne, wiedzę i gotowe
            rozwiązania w jednej przestrzeni. Wyszukuj, rozwijaj, testuj i
            upowszechniaj innowacje społeczne w Małopolsce.
          </p>

          <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <a
              href="#moduly"
              className="inline-flex h-12 w-full items-center justify-center rounded-full bg-indigo-600 px-6 text-base font-semibold text-white transition-colors hover:bg-indigo-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 sm:w-auto"
            >
              Zobacz moduły platformy
            </a>
            <a
              href="#o-projekcie"
              className="inline-flex h-12 w-full items-center justify-center rounded-full border border-slate-300 bg-white px-6 text-base font-semibold text-slate-700 transition-colors hover:bg-slate-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 sm:w-auto"
            >
              Dowiedz się więcej
            </a>
          </div>
        </section>

        <section id="moduly" aria-labelledby="moduly-heading" className="pb-20">
          <h2
            id="moduly-heading"
            className="mb-2 text-center text-2xl font-bold tracking-tight sm:text-3xl"
          >
            Komponenty platformy
          </h2>
          <p className="mx-auto mb-10 max-w-xl text-center text-slate-600">
            Siedem modułów, które połączą rozproszone dotąd procesy Małopolskiego
            Hubu Innowacji Społecznych.
          </p>

          <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {modules.map((module) => (
              <li
                key={module.number}
                className="flex flex-col rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition-shadow hover:shadow-md"
              >
                <div className="mb-4 flex items-center justify-between">
                  <span className="text-sm font-bold text-indigo-600">
                    {module.number}
                  </span>
                  {module.required ? (
                    <span className="rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-semibold text-amber-800">
                      Obligatoryjny
                    </span>
                  ) : null}
                </div>
                <h3 className="text-lg font-semibold tracking-tight">
                  {module.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-slate-600">
                  {module.description}
                </p>
              </li>
            ))}
          </ul>
        </section>

        <section
          id="o-projekcie"
          aria-labelledby="o-projekcie-heading"
          className="mb-20 rounded-3xl bg-indigo-600 px-8 py-12 text-center text-white sm:px-12"
        >
          <h2
            id="o-projekcie-heading"
            className="text-2xl font-bold tracking-tight sm:text-3xl"
          >
            Inteligentne narzędzie dla Małopolski
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-indigo-100">
            Platforma wykorzystuje sztuczną inteligencję, by automatycznie
            kojarzyć problemy z istniejącymi rozwiązaniami, wspierać pracowników
            Hubu w zarządzaniu wiedzą i otwierać przestrzeń do współpracy między
            mieszkańcami, samorządami i organizacjami.
          </p>
        </section>
      </main>

      <footer className="border-t border-slate-200 bg-white">
        <div className="mx-auto flex w-full max-w-6xl flex-col items-center justify-between gap-2 px-6 py-6 text-sm text-slate-500 sm:flex-row">
          <span>
            Regionalny Ośrodek Polityki Społecznej w Krakowie
          </span>
          <span>HubMI.pl — prototyp demonstracyjny</span>
        </div>
      </footer>
    </div>
  );
}
