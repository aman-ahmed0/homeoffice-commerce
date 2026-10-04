'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import ProductCard from '../components/ProductCard';

export default function HomePage() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
  console.log('DEBUG: useEffect running');                     // ← add this line
  fetch('/api/products')
    .then(res => {
      console.log('DEBUG: fetch response status', res.status);  // ← add this line
      return res.json();
    })
    .then(data => {
      console.log('DEBUG: products data', data);                // ← add this line
      setProducts(data);
      setLoading(false);
    })
    .catch(err => {
      console.error('Failed to fetch products:', err);
      setLoading(false);
    });
}, []);

  return (
    console.log('DEBUG render: loading =', loading, 'products length =', products.length),
    <div>
      <section className="bg-gradient-to-b from-gray-900 to-gray-950 py-20 text-center">
        <div className="max-w-4xl mx-auto px-4">
          <h1 className="text-5xl md:text-6xl font-extrabold text-white mb-6">
            Elevate Your{' '}
            <span className="text-accent-400">Home Office</span>
          </h1>
          <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
            Premium work-from-home essentials designed for productivity and comfort. Shipped by GitOps to Azure.
          </p>
          <Link href="#products" className="inline-block bg-accent-500 hover:bg-accent-600 text-white font-semibold py-3 px-8 rounded-lg transition-colors">
            Shop Now
          </Link>
        </div>
      </section>

      <section id="products" className="max-w-7xl mx-auto py-16 px-4 sm:px-6 lg:px-8">
        <h2 className="text-3xl font-bold text-white mb-8">Featured Products</h2>
        {loading ? (
          <div className="text-center text-gray-400">Loading products...</div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {products.map(product => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
}