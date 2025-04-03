import { describe, it, expect, beforeEach } from 'vitest';

describe('Usage Tracking Contract', () => {
  // Mock functions to simulate blockchain interactions
  
  const mockAdmin = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const mockRecipient = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
  
  let isAdmin = true;
  let usageRecords = new Map();
  let transitRoutes = new Map();
  let currentBlock = 100;
  
  // Mock contract functions
  const initializeUsageRecord = (recipient: string) => {
    if (!isAdmin) return { error: 100 };
    
    usageRecords.set(recipient, {
      totalTrips: 0,
      totalSpent: 0,
      lastTripTime: 0,
      tripHistory: []
    });
    
    return { success: true };
  };
  
  const addTransitRoute = (routeId: string, name: string, baseFare: number) => {
    if (!isAdmin) return { error: 100 };
    
    transitRoutes.set(routeId, {
      name,
      baseFare,
      active: true
    });
    
    return { success: true };
  };
  
  const updateRouteStatus = (routeId: string, active: boolean) => {
    if (!isAdmin) return { error: 100 };
    if (!transitRoutes.has(routeId)) return { error: 101 };
    
    const route = transitRoutes.get(routeId);
    transitRoutes.set(routeId, { ...route, active });
    
    return { success: true };
  };
  
  const recordTrip = (recipient: string, routeId: string, amount: number) => {
    if (!transitRoutes.has(routeId)) return { error: 101 };
    
    const route = transitRoutes.get(routeId);
    if (!route.active) return { error: 102 };
    
    // Initialize usage record if it doesn't exist
    if (!usageRecords.has(recipient)) {
      usageRecords.set(recipient, {
        totalTrips: 0,
        totalSpent: 0,
        lastTripTime: 0,
        tripHistory: []
      });
    }
    
    const usage = usageRecords.get(recipient);
    const newTrip = { time: currentBlock, amount, route: routeId };
    
    // Keep only the last 10 trips
    const updatedHistory = [newTrip, ...usage.tripHistory].slice(0, 10);
    
    usageRecords.set(recipient, {
      totalTrips: usage.totalTrips + 1,
      totalSpent: usage.totalSpent + amount,
      lastTripTime: currentBlock,
      tripHistory: updatedHistory
    });
    
    return { success: true };
  };
  
  const getUsageRecord = (recipient: string) => {
    return usageRecords.get(recipient) || null;
  };
  
  beforeEach(() => {
    isAdmin = true;
    usageRecords.clear();
    transitRoutes.clear();
    currentBlock = 100;
  });
  
  it('should initialize usage record for a recipient', () => {
    const result = initializeUsageRecord(mockRecipient);
    expect(result).toHaveProperty('success', true);
    
    const usage = usageRecords.get(mockRecipient);
    expect(usage.totalTrips).toBe(0);
    expect(usage.totalSpent).toBe(0);
  });
  
  it('should add a transit route', () => {
    const result = addTransitRoute('route-1', 'Downtown Express', 250);
    expect(result).toHaveProperty('success', true);
    
    const route = transitRoutes.get('route-1');
    expect(route.name).toBe('Downtown Express');
    expect(route.baseFare).toBe(250);
    expect(route.active).toBe(true);
  });
  
  it('should update route status', () => {
    addTransitRoute('route-1', 'Downtown Express', 250);
    
    const result = updateRouteStatus('route-1', false);
    expect(result).toHaveProperty('success', true);
    
    const route = transitRoutes.get('route-1');
    expect(route.active).toBe(false);
  });
  
  it('should not update non-existent route', () => {
    const result = updateRouteStatus('non-existent', false);
    expect(result).toHaveProperty('error', 101);
  });
  
  it('should record a trip', () => {
    addTransitRoute('route-1', 'Downtown Express', 250);
    initializeUsageRecord(mockRecipient);
    
    const result = recordTrip(mockRecipient, 'route-1', 250);
    expect(result).toHaveProperty('success', true);
    
    const usage = usageRecords.get(mockRecipient);
    expect(usage.totalTrips).toBe(1);
    expect(usage.totalSpent).toBe(250);
    expect(usage.lastTripTime).toBe(currentBlock);
    expect(usage.tripHistory.length).toBe(1);
  });
  
  it('should not record trip for inactive route', () => {
    addTransitRoute('route-1', 'Downtown Express', 250);
    updateRouteStatus('route-1', false);
    
    const result = recordTrip(mockRecipient, 'route-1', 250);
    expect(result).toHaveProperty('error', 102);
  });
});
