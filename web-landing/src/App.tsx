import { useTranslation } from 'react-i18next'
import Header from './components/layout/Header'
import Footer from './components/layout/Footer'
import Hero from './components/sections/Hero'
import HowItWorks from './components/sections/HowItWorks'
import Services from './components/sections/Services'
import TrustBadges from './components/sections/TrustBadges'
import ProviderCTA from './components/sections/ProviderCTA'
import ContactForm from './components/sections/ContactForm'

export default function App() {
  const { i18n } = useTranslation()
  document.documentElement.dir = i18n.language === 'ar' ? 'rtl' : 'ltr'
  document.documentElement.lang = i18n.language

  return (
    <>
      <Header />
      <main>
        <Hero />
        <HowItWorks />
        <Services />
        <TrustBadges />
        <ProviderCTA />
        <ContactForm />
      </main>
      <Footer />
    </>
  )
}
