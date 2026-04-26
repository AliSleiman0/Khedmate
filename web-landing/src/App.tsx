import Header from './components/layout/Header'
import Footer from './components/layout/Footer'
import Hero from './components/sections/Hero'
import Services from './components/sections/Services'
import HowItWorks from './components/sections/HowItWorks'
import PlatformStats from './components/sections/PlatformStats'
import ProviderCTA from './components/sections/ProviderCTA'
import ContactForm from './components/sections/ContactForm'

export default function App() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <Services />
        <HowItWorks />
        <PlatformStats />
        <ProviderCTA />
        <ContactForm />
      </main>
      <Footer />
    </>
  )
}
